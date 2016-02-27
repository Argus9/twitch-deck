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
	def digest top_streamers, new_users, total_users, total_activated_users, date
		@new_users = new_users
		@top_streamers = top_streamers
		@total_users = total_users
		@total_activated_users = total_activated_users
		@date = date
		mail to: 'jzisser9@gmail.com', subject: "TwitchDeck Daily Digest for #{ date }"
	end
end
