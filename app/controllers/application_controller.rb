class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, except: :replace_main_stream
	include SessionsHelper

	if Rails.env == 'production'
		scheduler = Rufus::Scheduler.new

		# Run daily at 6 AM.
		logger.info 'Setting up scheduler tasks to run at 6 AM.'
		scheduler.cron '*/5 * * * *' do # Temporarily run every 5 minutes to test.
		# scheduler.cron '0 6 * * *' do
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

			UserMailer.digest(top_streamers, new_users, total_users, activated_users, yesterday).deliver_now
			logger.info 'Sent TwitchDeck digest email to jzisser9@gmail.com.'

			# Cull inactive user accounts that are at least 30 days old.
			User.where('created_at <= ? AND activated = false', 30.days.ago).destroy_all
			logger.info 'Culled old inactive users.'
		end
	end
end
