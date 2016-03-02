class UserMailer < ApplicationMailer

	# Subject can be set in your I18n file at config/locales/en.yml
	# with the following lookup:
	#
	#   en.user_mailer.account_activation.subject
	#
	def account_activation user
		@user = user
		mail to: user.email, subject: 'Activate your TwitchDeck.io account'
	end

	# Subject can be set in your I18n file at config/locales/en.yml
	# with the following lookup:
	#
	#   en.user_mailer.password_reset.subject
	#
	def password_reset user
		@user = user
		mail to: user.email, subject: 'Reset your password'
	end

	##
	# Sends an email when a new user registers.
	def new_user user
		@user = user
		mail to: 'jzisser9@gmail.com', subject: "New TwitchDeck User: #{ @user.email }!"
	end

	##
	# Sends a daily digest email to the Admin user.
	def digest summary
		@new_users = summary.new_users
		@top_streamers = summary.top_streamers
		@total_users = summary.total_users
		@active_users = summary.active_users
		@culled_users = summary.culled_users
		@date = summary.date
		active_users_yesterday = DailySummary.find_by_date(@date - 1.day).active_users
		@user_growth = DailySummary.count < 2 ? '0%' :
			"#{(( @active_users.to_f - active_users_yesterday.to_f) * 100) / active_users_yesterday.to_f }%"
		mail to: 'jzisser9@gmail.com', subject: "TwitchDeck Daily Digest for #{ @date }"
	end
end
