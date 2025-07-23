# frozen_string_literal: true

# name: discourse-check-in
# about: Daily check-in system with points and rewards
# version: 0.1.0
# authors: Panda_CC
# url: https://github.com/werta666/Discourse-Check-in

enabled_site_setting :check_in_enabled

after_initialize do
  # Load plugin models and controllers
  load File.expand_path("app/models/check_in_record.rb", __dir__)
  load File.expand_path("app/models/user_point.rb", __dir__)
  load File.expand_path("app/models/point_transaction.rb", __dir__)
  load File.expand_path("app/controllers/check_in_controller.rb", __dir__)

  # Extend User model with check-in related methods
  add_to_class(:user, :check_in_records) { has_many :check_in_records, dependent: :destroy }
  add_to_class(:user, :user_point) { has_one :user_point, dependent: :destroy }
  add_to_class(:user, :point_transactions) { has_many :point_transactions, dependent: :destroy }

  add_to_class(:user, :total_points) do
    user_point&.total_points || 0
  end

  add_to_class(:user, :consecutive_check_in_days) do
    return 0 unless check_in_records.exists?

    today = Date.current
    consecutive_days = 0

    (0..365).each do |days_ago|
      date = today - days_ago.days
      record = check_in_records.find_by(check_in_date: date)

      if record
        consecutive_days += 1
      else
        break
      end
    end

    consecutive_days
  end

  add_to_class(:user, :checked_in_today?) do
    check_in_records.exists?(check_in_date: Date.current)
  end
end

# Add routes
Discourse::Application.routes.append do
  get "/check" => "check_in#index"
  post "/check/checkin" => "check_in#create"
  get "/check/status" => "check_in#status"
end
