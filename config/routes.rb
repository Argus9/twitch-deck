Rails.application.routes.draw do
	get 'logins/new'

	# The priority is based upon order of creation: first created -> highest priority.
	# See how all your routes lay out with "rake routes".

	# You can have the root of your site routed with "root"
	# root 'welcome#help'

	# Example of regular route:
	#   get 'products/:id' => 'catalog#view'

	# Example of named route that can be invoked with purchase_url(id: product.id)
	#   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

	# Example resource route (maps HTTP verbs to controller actions automatically):
	#   resources :products

	# Example resource route with options:
	#   resources :products do
	#     member do
	#       get 'short'
	#       post 'toggle'
	#     end
	#
	#     collection do
	#       get 'sold'
	#     end
	#   end

	# Example resource route with sub-resources:
	#   resources :products do
	#     resources :comments, :sales
	#     resource :sell
	#   end

	# Example resource route with more complex sub-resources:
	#   resources :products do
	#     resources :comments
	#     resources :sales do
	#       get 'recent', on: :collection
	#     end
	#   end

	# Example resource route with concerns:
	#   concern :toggleable do
	#     post 'toggle'
	#   end
	#   resources :posts, concerns: :toggleable
	#   resources :photos, concerns: :toggleable

	# Example resource route within a namespace:
	#   namespace :admin do
	#     # Directs /admin/products/* to Admin::ProductsController
	#     # (app/controllers/admin/products_controller.rb)
	#     resources :products
	#   end

	get '/google4727e3162513d814.html',
	    to: proc { |_| [200, {}, ['google-site-verification: google4727e3162513d814.html']] }
	get 'help', to: 'display#help'
	get 'users/update', controller: :users, action: :update
	get 'profile', controller: :users, action: :edit
	resources :users, only: [:new]
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
