class UsersController < ApplicationController
	before_action :logged_in_user, only: [:edit, :update]

	def show
		@user = User.find params[:id]
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new user_params
		if @user.save
			@user.send_activation_email
			flash[:info] = 'Please check your email to activate your account.'
			redirect_to root_url
		else
			render :new
		end
	end

	def edit
		if logged_in?
			@user = User.find current_user.id
		else
			redirect_to root_url
		end
	end

	def update
		@user = User.find params[:id]
		if @user.update_attribute :streamers, params['streamers']
			render nothing: true, status: :ok
		else
			render nothing: true, status: 500
		end
	end

	private

	def user_params
		params.require(:user).permit(:username, :email, :password, :password_confirmation)
	end

	##
	# Confirms a logged-in user.
	def logged_in_user
		unless logged_in?
			store_location
			flash[:danger] = 'Please log in.'
			redirect_to login_url
		end
	end
end
