class AddDateToDailySummaries < ActiveRecord::Migration
  def change
    add_column :daily_summaries, :date, :date
  end
end
