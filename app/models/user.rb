class User < ActiveRecord::Base
    has_secure_password

    validates_presence_of :username, :email
    validates :password, length: { minimum: 8 }
end
