class CreateDailySummaries < ActiveRecord::Migration
  def change
    create_table :daily_summaries do |t|
      t.integer :new_users
      t.string :top_streamers
      t.integer :total_users
      t.integer :active_users

      t.timestamps null: false
    end
  end
end
