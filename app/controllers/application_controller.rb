class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, except: :replace_main_stream
	include SessionsHelper

	if Rails.env == 'production'
		scheduler = Rufus::Scheduler.new

		# Run daily at 6 AM.
		logger.info 'Setting up scheduler tasks to run at 6 AM.'
		scheduler.cron '0 6 * * *' do
			# Cull inactive user accounts that are at least 30 days old.
			culled_users = User.destroy_all("created_at <= '#{ 30.days.ago.to_date }' AND activated = false").count
			logger.info "Culled #{ culled_users } inactive users."

			# Compile and send a daily digest of stats.
			yesterday = 1.day.ago.to_date
			new_users = User.where('DATE(created_at) = ?', yesterday).count
			total_users = User.count
			activated_users = User.where('activated = true').count

			streamer_counts = Hash.new(0)
			User.where('streamers is not null').select(:streamers).map(&:streamers).each do | streamers |
				streamers.split('&').each { | name | streamer_counts[name] += 1 }
			end
			top_streamers = streamer_counts.sort_by { |_, count| -count }[0...10]

			UserMailer.digest(top_streamers, new_users, total_users, activated_users, culled_users, yesterday).deliver_now
			logger.info 'Sent TwitchDeck digest email to jzisser9@gmail.com.'
		end
	end
end
