# frozen_string_literal: true

module ::DiscourseCheckIn
  class PointsController < ::ApplicationController
    requires_plugin DiscourseCheckIn::PLUGIN_NAME
    
    before_action :ensure_logged_in

    def show
      user_point = UserPoint.find_or_create_for_user(current_user)
      
      render json: {
        success: true,
        data: {
          total_points: user_point.total_points,
          user_id: current_user.id,
          username: current_user.username
        }
      }
    end

    def transactions
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 20
      per_page = [per_page, 100].min # Limit max per_page
      transaction_type = params[:type]

      transactions = current_user.point_transactions.recent
      transactions = transactions.by_type(transaction_type) if transaction_type.present?
      
      total_count = transactions.count
      transactions = transactions.limit(per_page).offset((page - 1) * per_page)

      transactions_data = transactions.map do |transaction|
        {
          id: transaction.id,
          points: transaction.points,
          formatted_points: transaction.formatted_points,
          transaction_type: transaction.transaction_type,
          description: transaction.description,
          check_in_record_id: transaction.check_in_record_id,
          created_at: transaction.created_at.iso8601,
          is_positive: transaction.positive?,
          is_negative: transaction.negative?
        }
      end

      render json: {
        success: true,
        data: {
          transactions: transactions_data,
          pagination: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            has_more: total_count > page * per_page
          },
          summary: {
            total_points: current_user.total_points,
            total_earned: current_user.point_transactions.where('points > 0').sum(:points),
            total_spent: current_user.point_transactions.where('points < 0').sum(:points).abs
          }
        }
      }
    end
  end
end
