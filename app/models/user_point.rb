# frozen_string_literal: true

class UserPoint < ActiveRecord::Base
  belongs_to :user
  has_many :point_transactions, through: :user

  validates :user_id, presence: true, uniqueness: true
  validates :total_points, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.find_or_create_for_user(user)
    find_or_create_by(user: user) do |user_point|
      user_point.total_points = 0
    end
  end

  def add_points(points, transaction_type, description = nil, check_in_record = nil)
    return false if points <= 0

    transaction do
      self.total_points += points
      save!

      PointTransaction.create!(
        user: user,
        points: points,
        transaction_type: transaction_type,
        description: description,
        check_in_record: check_in_record
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def deduct_points(points, transaction_type, description = nil)
    return false if points <= 0 || total_points < points

    transaction do
      self.total_points -= points
      save!

      PointTransaction.create!(
        user: user,
        points: -points,
        transaction_type: transaction_type,
        description: description
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def sufficient_points?(points)
    total_points >= points
  end
end
