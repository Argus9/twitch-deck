Rails.application.routes.draw do
  	get 'logins/new'
    get '/google4727e3162513d814.html',
	    to: proc { |_| [200, {}, ['google-site-verification: google4727e3162513d814.html']] }
	get 'help', to: 'display#help'
	get 'users/update', controller: :users, action: :update
	get 'profile', controller: :users, action: :edit
	resources :users, only: [:show, :new, :create, :edit]
	resources :account_activations, only: [:edit]
	resources :password_resets, only: [:new, :create, :edit, :update]
	get 'login' => 'sessions#new'
	post 'login' => 'sessions#create'
	delete 'logout' => 'sessions#destroy'
	get 'player/*streamers', to: 'display#embed_streams'
	get '*streamers', to: redirect('/player/%{streamers}')

	get '/', to: 'display#index'

	# If nothing else fits, take us to the main welcome landing.
	root 'display#index'
end
