# frozen_string_literal: true

class PointTransaction < ActiveRecord::Base
  self.table_name = 'point_transactions'
  belongs_to :user
  belongs_to :check_in_record, optional: true

  validates :user_id, presence: true
  validates :points, presence: true, numericality: true
  validates :transaction_type, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(transaction_type: type) }

  # Transaction types
  TRANSACTION_TYPES = {
    check_in: 'check_in',
    consecutive_bonus: 'consecutive_bonus',
    makeup_cost: 'makeup_cost',
    admin_adjustment: 'admin_adjustment'
  }.freeze

  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES.values }

  def self.create_check_in_transaction(user, points, check_in_record)
    create!(
      user: user,
      points: points,
      transaction_type: TRANSACTION_TYPES[:check_in],
      description: I18n.t('check_in.transaction.daily_check_in'),
      check_in_record: check_in_record
    )
  end

  def self.create_consecutive_bonus_transaction(user, points, check_in_record, consecutive_days)
    create!(
      user: user,
      points: points,
      transaction_type: TRANSACTION_TYPES[:consecutive_bonus],
      description: I18n.t('check_in.transaction.consecutive_bonus', days: consecutive_days),
      check_in_record: check_in_record
    )
  end

  def self.create_makeup_cost_transaction(user, points)
    create!(
      user: user,
      points: -points,
      transaction_type: TRANSACTION_TYPES[:makeup_cost],
      description: I18n.t('check_in.transaction.makeup_cost')
    )
  end

  def positive?
    points > 0
  end

  def negative?
    points < 0
  end

  def formatted_points
    points > 0 ? "+#{points}" : points.to_s
  end
end
