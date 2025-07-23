# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseCheckIn::CheckInController, type: :request do
  let(:user) { Fabricate(:user) }
  
  before do
    SiteSetting.check_in_enabled = true
    SiteSetting.check_in_daily_points = 10
    sign_in(user)
  end

  describe "POST /check-in/check-in" do
    context "when user hasn't checked in today" do
      it "creates a check-in record and awards points" do
        expect {
          post "/check-in/check-in"
        }.to change { CheckInRecord.count }.by(1)
         .and change { user.reload.total_points }.by(10)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["data"]["points_earned"]).to eq(10)
      end
    end

    context "when user has already checked in today" do
      before do
        CheckInRecord.create_check_in(user)
      end

      it "returns an error" do
        post "/check-in/check-in"
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to include("You have already checked in today")
      end
    end
  end

  describe "POST /check-in/makeup-check-in" do
    let(:yesterday) { Date.current - 1.day }
    
    before do
      SiteSetting.check_in_makeup_enabled = true
      SiteSetting.check_in_makeup_cost_points = 5
      user_point = UserPoint.find_or_create_for_user(user)
      user_point.update!(total_points: 20)
    end

    context "with valid date and sufficient points" do
      it "creates a makeup check-in record" do
        expect {
          post "/check-in/makeup-check-in", params: { date: yesterday.to_s }
        }.to change { CheckInRecord.count }.by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        
        record = CheckInRecord.last
        expect(record.is_makeup).to be true
        expect(record.check_in_date).to eq(yesterday)
      end
    end

    context "with insufficient points" do
      before do
        user.user_point.update!(total_points: 2)
      end

      it "returns an error" do
        post "/check-in/makeup-check-in", params: { date: yesterday.to_s }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end
    end
  end

  describe "GET /check-in/check-in-status" do
    it "returns user's check-in status" do
      get "/check-in/check-in-status"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["data"]).to have_key("checked_in_today")
      expect(json["data"]).to have_key("total_points")
      expect(json["data"]).to have_key("consecutive_days")
    end
  end

  describe "GET /check-in/check-in-records" do
    before do
      3.times do |i|
        CheckInRecord.create!(
          user: user,
          check_in_date: Date.current - i.days,
          points_earned: 10,
          consecutive_days: i + 1
        )
      end
    end

    it "returns user's check-in records" do
      get "/check-in/check-in-records"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["data"]["records"].length).to eq(3)
      expect(json["data"]["pagination"]).to have_key("total_count")
    end
  end
end
