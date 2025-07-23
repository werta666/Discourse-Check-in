# frozen_string_literal: true

# name: discourse-check-in
# about: Daily check-in system with points and rewards
# version: 0.1.0
# authors: Panda_CC
# url: https://github.com/werta666/Discourse-Check-in

enabled_site_setting :check_in_enabled

after_initialize do
  # Load controller
  load File.expand_path("app/controllers/check_in_controller.rb", __dir__)
end

# Add routes
Discourse::Application.routes.append do
  get "/check" => "check_in#index"
  post "/check/checkin" => "check_in#create"
  get "/check/status" => "check_in#status"
end
