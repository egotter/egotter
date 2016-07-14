Rails.application.routes.draw do
  root 'searches#new'

  resources :searches, only: [:new, :create, :show]
  get 'maintenance', to: 'searches#maintenance', as: :maintenance
  get 'privacy_policy', to: 'searches#privacy_policy', as: :privacy_policy
  get 'terms_of_service', to: 'searches#terms_of_service', as: :terms_of_service
  get 'sitemap', to: 'searches#sitemap', as: :sitemap
  get 'welcome', to: 'searches#welcome', as: :welcome
  get 'menu', to: 'searches#menu', as: :menu
  patch 'menu', to: 'searches#menu'
  get 'support', to: 'searches#support', as: :support
  get 'searches/:screen_name/waiting', to: 'searches#waiting', as: :waiting
  post 'searches/:screen_name/waiting', to: 'searches#waiting'
  get 'searches/:screen_name/statuses', to: 'searches#statuses', as: :statuses
  get 'searches/:screen_name/friends', to: 'searches#friends', as: :friends
  get 'searches/:screen_name/followers', to: 'searches#followers', as: :followers
  get 'searches/:screen_name/removing', to: 'searches#removing', as: :removing
  get 'searches/:screen_name/removed', to: 'searches#removed', as: :removed
  get 'searches/:screen_name/one_sided_friends', to: 'searches#one_sided_friends', as: :one_sided_friends
  get 'searches/:screen_name/one_sided_followers', to: 'searches#one_sided_followers', as: :one_sided_followers
  get 'searches/:screen_name/mutual_friends', to: 'searches#mutual_friends', as: :mutual_friends
  get 'searches/:screen_name/common_friends', to: 'searches#common_friends', as: :common_friends
  get 'searches/:screen_name/common_followers', to: 'searches#common_followers', as: :common_followers
  get 'searches/:screen_name/replying', to: 'searches#replying', as: :replying
  get 'searches/:screen_name/replied', to: 'searches#replied', as: :replied
  get 'searches/:screen_name/favoriting', to: 'searches#favoriting', as: :favoriting
  get 'searches/:screen_name/inactive_friends', to: 'searches#inactive_friends', as: :inactive_friends
  get 'searches/:screen_name/inactive_followers', to: 'searches#inactive_followers', as: :inactive_followers
  get 'searches/:screen_name/clusters_belong_to', to: 'searches#clusters_belong_to', as: :clusters_belong_to
  get 'searches/:screen_name/close_friends', to: 'searches#close_friends', as: :close_friends
  get 'searches/:screen_name/usage_stats', to: 'searches#usage_stats', as: :usage_stats
  get 'searches/:screen_name/update_histories', to: 'searches#update_histories', as: :update_histories

  get '/sign_in', to: 'searches#sign_in', as: :sign_in
  get '/sign_out', to: 'searches#sign_out', as: :sign_out

  devise_for :users, skip: [:sessions, :registrations, :password], controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  as :user do
    get '/_sign_out' => 'devise/sessions#destroy', :as => :destroy_user_session
    get '/' => 'devise/sessions#new', :as => :new_user_session
  end

  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end if Rails.env.production?
  mount Sidekiq::Web, at: '/sidekiq'

  get 'debug', to: 'searches#debug', as: :debug
  post 'clear_result_cache', to: 'searches#clear_result_cache', as: :clear_result_cache

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

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
  #     resource :seller
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
end
