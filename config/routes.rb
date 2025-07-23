# frozen_string_literal: true

DiscourseCheckIn::Engine.routes.draw do
  post "/check-in" => "check_in#create"
  post "/makeup-check-in" => "check_in#makeup"
  get "/check-in-records" => "check_in#records"
  get "/check-in-status" => "check_in#status"
  get "/points" => "points#show"
  get "/point-transactions" => "points#transactions"

  # Admin routes
  get "/admin/statistics" => "admin#statistics"
  get "/admin/user-points" => "admin#user_points"
  post "/admin/adjust-points" => "admin#adjust_points"
end

Discourse::Application.routes.draw { mount ::DiscourseCheckIn::Engine, at: "check-in" }
