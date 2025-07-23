# frozen_string_literal: true

class CheckInRecord < ActiveRecord::Base
  self.table_name = 'check_in_records'
  belongs_to :user
  has_many :point_transactions, dependent: :destroy

  validates :user_id, presence: true
  validates :check_in_date, presence: true, uniqueness: { scope: :user_id }
  validates :points_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :consecutive_days, presence: true, numericality: { greater_than_or_equal_to: 1 }

  scope :for_user, ->(user) { where(user: user) }
  scope :for_date, ->(date) { where(check_in_date: date) }
  scope :recent, -> { order(check_in_date: :desc) }
  scope :makeup_records, -> { where(is_makeup: true) }
  scope :regular_records, -> { where(is_makeup: false) }

  def self.checked_in_today?(user)
    exists?(user: user, check_in_date: Date.current)
  end

  def self.last_check_in_for_user(user)
    for_user(user).recent.first
  end

  def self.consecutive_days_for_user(user)
    return 0 unless exists?(user: user)

    today = Date.current
    consecutive_days = 0

    (0..365).each do |days_ago|
      date = today - days_ago.days
      record = for_user(user).for_date(date).first

      if record
        consecutive_days += 1
      else
        break
      end
    end

    consecutive_days
  end

  def self.can_makeup_for_date?(user, date)
    return false if date >= Date.current
    return false if exists?(user: user, check_in_date: date)

    max_days = SiteSetting.check_in_makeup_max_days
    return false if date < Date.current - max_days.days

    true
  end

  def self.create_check_in(user, date = Date.current, is_makeup = false)
    consecutive_days = consecutive_days_for_user(user)
    
    # If this is not a makeup and there's a gap, reset consecutive days
    if !is_makeup && date == Date.current
      last_record = last_check_in_for_user(user)
      if last_record && last_record.check_in_date != Date.current - 1.day
        consecutive_days = 1
      else
        consecutive_days += 1
      end
    elsif is_makeup
      # For makeup, don't change consecutive days calculation
      consecutive_days = consecutive_days_for_user(user) + 1
    end

    daily_points = SiteSetting.check_in_daily_points
    bonus_points = 0

    # Calculate consecutive bonus
    if SiteSetting.check_in_consecutive_bonus_enabled &&
       consecutive_days >= SiteSetting.check_in_consecutive_bonus_days &&
       consecutive_days % SiteSetting.check_in_consecutive_bonus_days == 0
      bonus_points = SiteSetting.check_in_consecutive_bonus_points
    end

    total_points = daily_points + bonus_points

    create!(
      user: user,
      check_in_date: date,
      is_makeup: is_makeup,
      points_earned: total_points,
      consecutive_days: consecutive_days
    )
  end
end
