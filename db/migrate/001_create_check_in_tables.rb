# frozen_string_literal: true

class CreateCheckInTables < ActiveRecord::Migration[7.0]
  def up
    # Create user_points table
    create_table :user_points do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.integer :total_points, default: 0, null: false
      t.timestamps
    end

    # Create check_in_records table
    create_table :check_in_records do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.date :check_in_date, null: false
      t.boolean :is_makeup, default: false, null: false
      t.integer :points_earned, default: 0, null: false
      t.integer :consecutive_days, default: 1, null: false
      t.timestamps
    end

    # Create point_transactions table
    create_table :point_transactions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.integer :points, null: false
      t.string :transaction_type, null: false
      t.text :description
      t.references :check_in_record, null: true, foreign_key: true
      t.timestamps
    end

    # Add indexes for better performance
    add_index :check_in_records, [:user_id, :check_in_date], unique: true
    add_index :check_in_records, :check_in_date
    add_index :point_transactions, :transaction_type
    add_index :point_transactions, :created_at
  end

  def down
    drop_table :point_transactions
    drop_table :check_in_records
    drop_table :user_points
  end
end
