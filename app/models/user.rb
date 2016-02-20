class User < ActiveRecord::Base
	attr_accessor :remember_token

	has_secure_password

	validates_presence_of :username, :email
	validates_uniqueness_of :username, :email
	validates :password, length: { minimum: 8 }

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
	def authenticated? remember_token
		remember_digest.nil? ? false : BCrypt::Password.new(remember_digest).is_password?(remember_token)
	end

	##
	# Forgets a user.
	def forget
		update_attribute :remember_digest, nil
	end
end
