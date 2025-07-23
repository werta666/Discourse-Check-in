# frozen_string_literal: true

class CreateCheckInTables < ActiveRecord::Migration[6.0]
  def change
    # Create user_points table
    create_table :user_points do |t|
      t.integer :user_id, null: false
      t.integer :total_points, default: 0, null: false
      t.timestamps null: false
    end

    add_index :user_points, :user_id, unique: true

    # Create check_in_records table
    create_table :check_in_records do |t|
      t.integer :user_id, null: false
      t.date :check_in_date, null: false
      t.boolean :is_makeup, default: false, null: false
      t.integer :points_earned, default: 0, null: false
      t.integer :consecutive_days, default: 1, null: false
      t.timestamps null: false
    end

    add_index :check_in_records, :user_id
    add_index :check_in_records, [:user_id, :check_in_date], unique: true
    add_index :check_in_records, :check_in_date

    # Create point_transactions table
    create_table :point_transactions do |t|
      t.integer :user_id, null: false
      t.integer :points, null: false
      t.string :transaction_type, null: false
      t.text :description
      t.integer :check_in_record_id, null: true
      t.timestamps null: false
    end

    add_index :point_transactions, :user_id
    add_index :point_transactions, :transaction_type
    add_index :point_transactions, :created_at
    add_index :point_transactions, :check_in_record_id
  end
end
