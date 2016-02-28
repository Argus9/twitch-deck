class AddCulledUsersToDailySummaries < ActiveRecord::Migration
	def up
		add_column :daily_summaries, :culled_users, :integer

		# Create an initial summary if none exist.
		if DailySummary.count == 0
			summary = DailySummary.new
			summary.culled_users = 0
			summary.date = Date.today
			summary.new_users = 0
			summary.total_users = User.count
			summary.active_users = User.where('activated = true').count

			streamer_counts = Hash.new(0)
			User.where('streamers is not null').select(:streamers).map(&:streamers).each do | streamers |
				streamers.split('&').each { | name | streamer_counts[name] += 1 }
			end
			summary.top_streamers = streamer_counts.sort_by { |_, count| -count }[0...10]
			summary.save!
		end
	end

	def down
		remove_column :daily_summaries, :culled_users
	end
end
