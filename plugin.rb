# frozen_string_literal: true

# name: discourse-check-in
# about: A comprehensive check-in plugin with points system, consecutive rewards, and makeup functionality
# meta_topic_id: TODO
# version: 0.1.0
# authors: Panda_CC
# url: https://github.com/werta666/Discourse-Check-in
# required_version: 2.7.0

enabled_site_setting :check_in_enabled

module ::DiscourseCheckIn
  PLUGIN_NAME = "discourse-check-in"
end

require_relative "lib/discourse_check_in/engine"

after_initialize do
  # Load plugin models, controllers, and services
  require_relative "app/models/check_in_record"
  require_relative "app/models/user_point"
  require_relative "app/models/point_transaction"
  require_relative "app/services/check_in_service"

  # Extend User model with check-in related methods
  User.class_eval do
    has_many :check_in_records, dependent: :destroy
    has_one :user_point, dependent: :destroy
    has_many :point_transactions, dependent: :destroy

    def total_points
      user_point&.total_points || 0
    end

    def consecutive_check_in_days
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

    def checked_in_today?
      check_in_records.exists?(check_in_date: Date.current)
    end
  end
end
