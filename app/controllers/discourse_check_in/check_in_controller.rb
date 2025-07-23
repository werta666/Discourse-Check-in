# frozen_string_literal: true

module ::DiscourseCheckIn
  class CheckInController < ::ApplicationController
    requires_plugin DiscourseCheckIn::PLUGIN_NAME
    
    before_action :ensure_logged_in
    before_action :ensure_check_in_enabled

    def index
      # 渲染签到主页面
    end

    def create
      service = CheckInService.new(current_user)
      result = service.check_in_today

      if result[:success]
        render json: {
          success: true,
          message: I18n.t('check_in.success.checked_in'),
          data: {
            points_earned: result[:points_earned],
            consecutive_days: result[:consecutive_days],
            bonus_points: result[:bonus_points],
            total_points: current_user.total_points
          }
        }
      else
        render json: {
          success: false,
          errors: service.errors
        }, status: :unprocessable_entity
      end
    end

    def makeup
      date = params[:date]
      return render_error(I18n.t('check_in.errors.date_required')) if date.blank?

      service = CheckInService.new(current_user)
      result = service.makeup_check_in(date)

      if result[:success]
        render json: {
          success: true,
          message: I18n.t('check_in.success.makeup_completed'),
          data: {
            date: date,
            points_earned: result[:points_earned],
            makeup_cost: result[:makeup_cost],
            net_points: result[:net_points],
            total_points: current_user.total_points
          }
        }
      else
        render json: {
          success: false,
          errors: service.errors
        }, status: :unprocessable_entity
      end
    end

    def records
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 20
      per_page = [per_page, 100].min # Limit max per_page

      service = CheckInService.new(current_user)
      result = service.get_check_in_records(page, per_page)

      records_data = result[:records].map do |record|
        {
          id: record.id,
          check_in_date: record.check_in_date.strftime('%Y-%m-%d'),
          is_makeup: record.is_makeup,
          points_earned: record.points_earned,
          consecutive_days: record.consecutive_days,
          created_at: record.created_at.iso8601
        }
      end

      render json: {
        success: true,
        data: {
          records: records_data,
          pagination: {
            page: result[:page],
            per_page: result[:per_page],
            total_count: result[:total_count],
            has_more: result[:has_more]
          }
        }
      }
    end

    def status
      service = CheckInService.new(current_user)
      status_data = service.get_check_in_status

      render json: {
        success: true,
        data: status_data
      }
    end

    private

    def ensure_check_in_enabled
      unless SiteSetting.check_in_enabled
        render json: {
          success: false,
          errors: [I18n.t('check_in.errors.disabled')]
        }, status: :forbidden
      end
    end

    def render_error(message, status = :bad_request)
      render json: {
        success: false,
        errors: [message]
      }, status: status
    end
  end
end
