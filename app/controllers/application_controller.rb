class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, except: :replace_main_stream
	include SessionsHelper

	scheduler = Rufus::Scheduler.start_new

	# Run daily at 6 AM.
	scheduler.cron '0 0 6 1/1 * ? *' do
		# Compile and send a daily digest of stats.
		yesterday = 1.day.ago.to_date
		new_users = User.where('DATE(created_at) = ?', yesterday).count
		total_users = User.count
		activated_users = User.where('activated = true').count

		streamers = new Hash 0
		User.where('streamers is not null').select(:streamers).map(&:streamers).each do |streamers|
			streamers.split('&').each { |streamer| streamers[streamer] += 1 }
		end

		top_streamers = streamers.sort_by { |_, count| -count }[0...10]

		UserMailer.digest(top_streamers, new_users, total_users, activated_users, yesterday).deliver_now

		# Cull inactive user accounts that are at least 30 days old.
		User.where('created_at <= ? AND activated = false', 30.days.ago).destroy_all
	end
end
