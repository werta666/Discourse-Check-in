# frozen_string_literal: true

class CheckInService
  attr_reader :user, :errors

  def initialize(user)
    @user = user
    @errors = []
  end

  def check_in_today
    return add_error(I18n.t('check_in.errors.already_checked_in')) if already_checked_in_today?
    return add_error(I18n.t('check_in.errors.disabled')) unless check_in_enabled?

    ActiveRecord::Base.transaction do
      # Create check-in record
      check_in_record = CheckInRecord.create_check_in(user)
      
      # Get or create user points
      user_point = UserPoint.find_or_create_for_user(user)
      
      # Calculate points
      daily_points = SiteSetting.check_in_daily_points
      bonus_points = calculate_consecutive_bonus(check_in_record.consecutive_days)
      total_points = daily_points + bonus_points
      
      # Add points to user
      user_point.add_points(
        total_points,
        PointTransaction::TRANSACTION_TYPES[:check_in],
        I18n.t('check_in.transaction.daily_check_in'),
        check_in_record
      )
      
      # Add consecutive bonus transaction if applicable
      if bonus_points > 0
        PointTransaction.create_consecutive_bonus_transaction(
          user,
          bonus_points,
          check_in_record,
          check_in_record.consecutive_days
        )
      end
      
      {
        success: true,
        check_in_record: check_in_record,
        points_earned: total_points,
        consecutive_days: check_in_record.consecutive_days,
        bonus_points: bonus_points
      }
    end
  rescue ActiveRecord::RecordInvalid => e
    add_error(e.message)
    { success: false, errors: @errors }
  end

  def makeup_check_in(date)
    date = Date.parse(date.to_s) if date.is_a?(String)
    
    return add_error(I18n.t('check_in.errors.makeup_disabled')) unless makeup_enabled?
    return add_error(I18n.t('check_in.errors.invalid_makeup_date')) unless valid_makeup_date?(date)
    return add_error(I18n.t('check_in.errors.already_checked_in_date')) if already_checked_in_date?(date)
    
    user_point = UserPoint.find_or_create_for_user(user)
    makeup_cost = SiteSetting.check_in_makeup_cost_points
    
    return add_error(I18n.t('check_in.errors.insufficient_points')) unless user_point.sufficient_points?(makeup_cost)

    ActiveRecord::Base.transaction do
      # Deduct makeup cost
      user_point.deduct_points(
        makeup_cost,
        PointTransaction::TRANSACTION_TYPES[:makeup_cost],
        I18n.t('check_in.transaction.makeup_cost')
      )
      
      # Create makeup check-in record
      check_in_record = CheckInRecord.create_check_in(user, date, true)
      
      # Add daily points for makeup
      daily_points = SiteSetting.check_in_daily_points
      user_point.add_points(
        daily_points,
        PointTransaction::TRANSACTION_TYPES[:check_in],
        I18n.t('check_in.transaction.makeup_check_in', date: date.strftime('%Y-%m-%d')),
        check_in_record
      )
      
      {
        success: true,
        check_in_record: check_in_record,
        points_earned: daily_points,
        makeup_cost: makeup_cost,
        net_points: daily_points - makeup_cost
      }
    end
  rescue ActiveRecord::RecordInvalid => e
    add_error(e.message)
    { success: false, errors: @errors }
  end

  def get_check_in_status
    user_point = UserPoint.find_or_create_for_user(user)
    consecutive_days = CheckInRecord.consecutive_days_for_user(user)
    
    {
      checked_in_today: already_checked_in_today?,
      total_points: user_point.total_points,
      consecutive_days: consecutive_days,
      can_check_in: can_check_in_today?,
      next_bonus_in: next_bonus_in_days(consecutive_days),
      settings: {
        daily_points: SiteSetting.check_in_daily_points,
        consecutive_bonus_enabled: SiteSetting.check_in_consecutive_bonus_enabled,
        consecutive_bonus_days: SiteSetting.check_in_consecutive_bonus_days,
        consecutive_bonus_points: SiteSetting.check_in_consecutive_bonus_points,
        makeup_enabled: SiteSetting.check_in_makeup_enabled,
        makeup_cost: SiteSetting.check_in_makeup_cost_points,
        makeup_max_days: SiteSetting.check_in_makeup_max_days
      }
    }
  end

  def get_check_in_records(page = 1, per_page = 20)
    records = user.check_in_records
                  .includes(:point_transactions)
                  .recent
                  .limit(per_page)
                  .offset((page - 1) * per_page)
    
    {
      records: records,
      total_count: user.check_in_records.count,
      page: page,
      per_page: per_page,
      has_more: user.check_in_records.count > page * per_page
    }
  end

  private

  def already_checked_in_today?
    CheckInRecord.checked_in_today?(user)
  end

  def already_checked_in_date?(date)
    CheckInRecord.exists?(user: user, check_in_date: date)
  end

  def can_check_in_today?
    check_in_enabled? && !already_checked_in_today?
  end

  def check_in_enabled?
    SiteSetting.check_in_enabled
  end

  def makeup_enabled?
    SiteSetting.check_in_makeup_enabled
  end

  def valid_makeup_date?(date)
    return false if date >= Date.current
    return false if date < Date.current - SiteSetting.check_in_makeup_max_days.days
    true
  end

  def calculate_consecutive_bonus(consecutive_days)
    return 0 unless SiteSetting.check_in_consecutive_bonus_enabled
    return 0 unless consecutive_days >= SiteSetting.check_in_consecutive_bonus_days
    return 0 unless consecutive_days % SiteSetting.check_in_consecutive_bonus_days == 0
    
    SiteSetting.check_in_consecutive_bonus_points
  end

  def next_bonus_in_days(consecutive_days)
    return nil unless SiteSetting.check_in_consecutive_bonus_enabled
    
    bonus_days = SiteSetting.check_in_consecutive_bonus_days
    (bonus_days - (consecutive_days % bonus_days)) % bonus_days
  end

  def add_error(message)
    @errors << message
    false
  end
end
