# frozen_string_literal: true

module ::DiscourseCheckIn
  class AdminController < ::Admin::AdminController
    requires_plugin DiscourseCheckIn::PLUGIN_NAME

    def statistics
      # Get overall statistics
      total_users_checked_in = CheckInRecord.distinct.count(:user_id)
      total_check_ins = CheckInRecord.count
      total_makeup_check_ins = CheckInRecord.makeup_records.count
      total_points_distributed = PointTransaction.where('points > 0').sum(:points)
      
      # Get recent activity (last 30 days)
      recent_check_ins = CheckInRecord.where('created_at > ?', 30.days.ago).count
      recent_new_users = CheckInRecord.where('created_at > ?', 30.days.ago).distinct.count(:user_id)
      
      # Get top users by points
      top_users = User.joins(:user_point)
                     .order('user_points.total_points DESC')
                     .limit(10)
                     .select('users.id, users.username, user_points.total_points')
      
      # Get daily check-in stats for the last 7 days
      daily_stats = []
      7.times do |i|
        date = Date.current - i.days
        count = CheckInRecord.where(check_in_date: date).count
        daily_stats << {
          date: date.strftime('%Y-%m-%d'),
          count: count
        }
      end
      daily_stats.reverse!

      render json: {
        success: true,
        data: {
          overview: {
            total_users_checked_in: total_users_checked_in,
            total_check_ins: total_check_ins,
            total_makeup_check_ins: total_makeup_check_ins,
            total_points_distributed: total_points_distributed,
            recent_check_ins: recent_check_ins,
            recent_new_users: recent_new_users
          },
          top_users: top_users.map do |user|
            {
              id: user.id,
              username: user.username,
              total_points: user.total_points
            }
          end,
          daily_stats: daily_stats
        }
      }
    end

    def user_points
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 20
      per_page = [per_page, 100].min
      search = params[:search]

      users_query = User.joins(:user_point).includes(:user_point)
      users_query = users_query.where('users.username ILIKE ?', "%#{search}%") if search.present?
      
      total_count = users_query.count
      users = users_query.order('user_points.total_points DESC')
                        .limit(per_page)
                        .offset((page - 1) * per_page)

      users_data = users.map do |user|
        {
          id: user.id,
          username: user.username,
          avatar_template: user.avatar_template,
          total_points: user.total_points,
          check_in_count: user.check_in_records.count,
          last_check_in: user.check_in_records.recent.first&.check_in_date&.strftime('%Y-%m-%d'),
          consecutive_days: user.consecutive_check_in_days
        }
      end

      render json: {
        success: true,
        data: {
          users: users_data,
          pagination: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            has_more: total_count > page * per_page
          }
        }
      }
    end

    def adjust_points
      user_id = params[:user_id]
      points = params[:points]&.to_i
      reason = params[:reason]

      return render_error('User ID is required') if user_id.blank?
      return render_error('Points value is required') if points.nil?
      return render_error('Reason is required') if reason.blank?

      user = User.find_by(id: user_id)
      return render_error('User not found') unless user

      user_point = UserPoint.find_or_create_for_user(user)

      if points > 0
        success = user_point.add_points(
          points,
          PointTransaction::TRANSACTION_TYPES[:admin_adjustment],
          "Admin adjustment: #{reason}"
        )
      else
        success = user_point.deduct_points(
          points.abs,
          PointTransaction::TRANSACTION_TYPES[:admin_adjustment],
          "Admin adjustment: #{reason}"
        )
      end

      if success
        render json: {
          success: true,
          message: I18n.t('check_in.admin.points_adjusted'),
          data: {
            user_id: user.id,
            username: user.username,
            new_total_points: user_point.total_points,
            adjustment: points
          }
        }
      else
        render_error('Failed to adjust points')
      end
    end

    private

    def render_error(message, status = :bad_request)
      render json: {
        success: false,
        errors: [message]
      }, status: status
    end
  end
end
