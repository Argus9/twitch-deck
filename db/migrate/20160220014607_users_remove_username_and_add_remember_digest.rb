class UsersRemoveUsernameAndAddRememberDigest < ActiveRecord::Migration
	def change
		remove_column :users, :username
		add_column :users, :remember_digest, :string
	end
end
