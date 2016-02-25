class User < ActiveRecord::Base
	has_many :tips

	attr_accessor :remember_token, :activation_token, :reset_token
	before_save :downcase_email
	before_create :create_activation_digest

	has_secure_password

	validates_presence_of :email
	validates_uniqueness_of :email
	validates :password, presence: true, length: { minimum: 8 }, allow_nil: false

	#
	# Returns the hash digest of the given string.
	def self.digest string
		cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
		BCrypt::Password.create string, cost: cost
	end

	##
	# Generates a new remember token.
	def self.new_token
		SecureRandom.urlsafe_base64
	end

	def remember
		self.remember_token = User.new_token
		update_attribute :remember_digest, User.digest(remember_token)
	end

	##
	# Returns true if the given token matches the digest.
	def authenticated? attribute, token
		digest = send "#{ attribute }_digest"
		return false if digest.nil?
		BCrypt::Password.new(digest).is_password? token
	end

	##
	# Forgets a user.
	def forget
		update_attribute :remember_digest, nil
	end

	##
	# Activates an account.
	def activate
		update_attribute :activated, true
		update_attribute :activated_at, Time.zone.now
	end

	##
	# Sends activation email.
	def send_activation_email
		UserMailer.account_activation(self).deliver_now
	end

	##
	# Sends an email to the admin to let them know a new user registered.
	def send_new_user_email
		UserMailer.new_user(self).deliver_now
	end

	##
	# Sets the password reset attributes on the user.
	def create_reset_digest
		self.reset_token = User.new_token
		update_attribute :reset_digest, User.digest(reset_token)
		update_attribute :reset_sent_at, Time.zone.now
	end

	##
	# Sends password reset email.
	def send_password_reset_email
		UserMailer.password_reset(self).deliver_now
	end

	##
	# Returns true if a password reset has expired.
	def password_reset_expired?
		reset_sent_at < 2.hours.ago
	end

	private

	##
	# Converts email to all lower-case.
	def downcase_email
		self.email = email.downcase
	end

	##
	# Creates and assigns the activation token and digest.
	def create_activation_digest
		self.activation_token = User.new_token
		self.activation_digest = User.digest activation_token
	end
end
