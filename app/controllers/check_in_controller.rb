# frozen_string_literal: true

class CheckInController < ::ApplicationController
  def index
    render plain: "签到页面测试 - 如果您看到这个消息，说明路由工作正常！"
  end

  def create
    result = perform_check_in
    
    if result[:success]
      render json: {
        success: true,
        message: "签到成功！",
        data: result[:data]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: 422
    end
  end

  def status
    user_point = current_user.user_point || UserPoint.create(user: current_user)
    today_record = current_user.check_in_records.where(check_in_date: Date.current).first
    
    render json: {
      success: true,
      data: {
        total_points: user_point.total_points,
        checked_in_today: today_record.present?,
        consecutive_days: today_record&.consecutive_days || 0
      }
    }
  end

  private

  def perform_check_in
    return { success: false, error: "今天已经签到过了" } if already_checked_in_today?

    points_earned = SiteSetting.check_in_daily_points || 10
    consecutive_days = calculate_consecutive_days
    bonus_points = calculate_bonus_points(consecutive_days)
    total_points_earned = points_earned + bonus_points

    ActiveRecord::Base.transaction do
      # 创建签到记录
      check_in_record = current_user.check_in_records.create!(
        check_in_date: Date.current,
        points_earned: total_points_earned,
        consecutive_days: consecutive_days,
        is_makeup: false
      )

      # 更新用户积分
      user_point = current_user.user_point || UserPoint.create!(user: current_user)
      user_point.increment!(:total_points, total_points_earned)

      # 创建积分交易记录
      PointTransaction.create!(
        user: current_user,
        points: total_points_earned,
        transaction_type: 'daily_check_in',
        description: "每日签到奖励",
        check_in_record: check_in_record
      )

      if bonus_points > 0
        PointTransaction.create!(
          user: current_user,
          points: bonus_points,
          transaction_type: 'consecutive_bonus',
          description: "连续签到奖励（#{consecutive_days}天）",
          check_in_record: check_in_record
        )
      end
    end

    {
      success: true,
      data: {
        points_earned: total_points_earned,
        consecutive_days: consecutive_days,
        bonus_points: bonus_points,
        total_points: current_user.user_point.total_points
      }
    }
  rescue => e
    Rails.logger.error "Check-in error: #{e.message}"
    { success: false, error: "签到失败，请重试" }
  end

  def already_checked_in_today?
    current_user.check_in_records.exists?(check_in_date: Date.current)
  end

  def calculate_consecutive_days
    last_record = current_user.check_in_records
                             .where('check_in_date < ?', Date.current)
                             .order(check_in_date: :desc)
                             .first

    return 1 unless last_record
    return 1 if last_record.check_in_date < Date.current - 1.day

    last_record.consecutive_days + 1
  end

  def calculate_bonus_points(consecutive_days)
    return 0 unless SiteSetting.check_in_consecutive_bonus_enabled

    case consecutive_days
    when 7..13
      SiteSetting.check_in_weekly_bonus_points || 20
    when 14..29
      SiteSetting.check_in_biweekly_bonus_points || 50
    when 30..Float::INFINITY
      SiteSetting.check_in_monthly_bonus_points || 100
    else
      0
    end
  end
end
