class AddCulledUsersToDailySummaries < ActiveRecord::Migration
	def change
		add_column :daily_summaries, :culled_users, :integer
	end
end
