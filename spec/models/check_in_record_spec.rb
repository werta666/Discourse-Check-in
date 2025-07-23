# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckInRecord, type: :model do
  let(:user) { Fabricate(:user) }

  describe "validations" do
    it "validates presence of required fields" do
      record = CheckInRecord.new
      expect(record).not_to be_valid
      expect(record.errors[:user_id]).to include("can't be blank")
      expect(record.errors[:check_in_date]).to include("can't be blank")
    end

    it "validates uniqueness of check_in_date per user" do
      CheckInRecord.create!(
        user: user,
        check_in_date: Date.current,
        points_earned: 10,
        consecutive_days: 1
      )

      duplicate = CheckInRecord.new(
        user: user,
        check_in_date: Date.current,
        points_earned: 10,
        consecutive_days: 1
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:check_in_date]).to include("has already been taken")
    end
  end

  describe ".checked_in_today?" do
    it "returns true if user checked in today" do
      CheckInRecord.create!(
        user: user,
        check_in_date: Date.current,
        points_earned: 10,
        consecutive_days: 1
      )

      expect(CheckInRecord.checked_in_today?(user)).to be true
    end

    it "returns false if user hasn't checked in today" do
      expect(CheckInRecord.checked_in_today?(user)).to be false
    end
  end

  describe ".consecutive_days_for_user" do
    it "calculates consecutive days correctly" do
      # Create consecutive check-ins for 3 days
      3.times do |i|
        CheckInRecord.create!(
          user: user,
          check_in_date: Date.current - i.days,
          points_earned: 10,
          consecutive_days: i + 1
        )
      end

      expect(CheckInRecord.consecutive_days_for_user(user)).to eq(3)
    end

    it "stops counting at the first gap" do
      # Create check-ins with a gap
      CheckInRecord.create!(
        user: user,
        check_in_date: Date.current,
        points_earned: 10,
        consecutive_days: 1
      )

      CheckInRecord.create!(
        user: user,
        check_in_date: Date.current - 2.days, # Gap at yesterday
        points_earned: 10,
        consecutive_days: 1
      )

      expect(CheckInRecord.consecutive_days_for_user(user)).to eq(1)
    end
  end

  describe ".can_makeup_for_date?" do
    before do
      SiteSetting.check_in_makeup_max_days = 7
    end

    it "returns true for valid makeup dates" do
      yesterday = Date.current - 1.day
      expect(CheckInRecord.can_makeup_for_date?(user, yesterday)).to be true
    end

    it "returns false for future dates" do
      tomorrow = Date.current + 1.day
      expect(CheckInRecord.can_makeup_for_date?(user, tomorrow)).to be false
    end

    it "returns false for dates beyond max makeup days" do
      old_date = Date.current - 10.days
      expect(CheckInRecord.can_makeup_for_date?(user, old_date)).to be false
    end

    it "returns false if already checked in for that date" do
      yesterday = Date.current - 1.day
      CheckInRecord.create!(
        user: user,
        check_in_date: yesterday,
        points_earned: 10,
        consecutive_days: 1
      )

      expect(CheckInRecord.can_makeup_for_date?(user, yesterday)).to be false
    end
  end

  describe ".create_check_in" do
    before do
      SiteSetting.check_in_daily_points = 10
      SiteSetting.check_in_consecutive_bonus_enabled = true
      SiteSetting.check_in_consecutive_bonus_days = 3
      SiteSetting.check_in_consecutive_bonus_points = 5
    end

    it "creates a check-in record with correct points" do
      record = CheckInRecord.create_check_in(user)
      
      expect(record).to be_persisted
      expect(record.user).to eq(user)
      expect(record.check_in_date).to eq(Date.current)
      expect(record.points_earned).to eq(10)
      expect(record.consecutive_days).to eq(1)
      expect(record.is_makeup).to be false
    end

    it "awards consecutive bonus when applicable" do
      # Create 2 previous consecutive check-ins
      2.times do |i|
        CheckInRecord.create!(
          user: user,
          check_in_date: Date.current - (i + 1).days,
          points_earned: 10,
          consecutive_days: i + 1
        )
      end

      record = CheckInRecord.create_check_in(user)
      
      # Should get bonus on 3rd consecutive day
      expect(record.points_earned).to eq(15) # 10 + 5 bonus
      expect(record.consecutive_days).to eq(3)
    end
  end
end
