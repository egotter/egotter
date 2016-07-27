Rails.application.routes.draw do
  root 'searches#new'

  resources :searches, only: [:new, :create, :show]
  get 'maintenance', to: 'searches#maintenance', as: :maintenance
  get 'privacy_policy', to: 'searches#privacy_policy', as: :privacy_policy
  get 'terms_of_service', to: 'searches#terms_of_service', as: :terms_of_service
  get 'sitemap', to: 'searches#sitemap', as: :sitemap
  get 'menu', to: 'searches#menu', as: :menu
  patch 'menu', to: 'searches#menu'
  get 'support', to: 'searches#support', as: :support
  get 'searches/:screen_name/waiting', to: 'searches#waiting', as: :waiting
  post 'searches/:screen_name/waiting', to: 'searches#waiting'

  %i(friends followers removing removed blocking_or_blocked one_sided_friends one_sided_followers
    mutual_friends common_friends common_followers replying replied favoriting inactive_friends
    inactive_followers clusters_belong_to close_friends usage_stats).each do |name|
    get "searches/:screen_name/#{name}", to: "searches##{name}", as: name
  end

  %i(statuses update_histories).each do |name|
    get "searches/:screen_name/#{name}" => redirect("/#{name}/%{id}")
  end

  resource :search_histories, only: :show
  resource :information, only: :show
  get '/statuses/keyword_timeline', to: 'statuses#keyword_timeline', as: :keyword_timeline
  resources :statuses, only: :show
  resources :update_histories, only: :show

  delete 'caches', to: 'caches#destroy', as: :caches_delete

  get '/sign_in', to: 'login#sign_in', as: :sign_in
  get '/sign_out', to: 'login#sign_out', as: :sign_out
  get '/welcome', to: 'login#welcome', as: :welcome

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

  get 'kpis', to: 'kpis#index', as: :kpis
  get 'kpis/rr', to: 'kpis#rr', as: :rr
  get 'debug', to: 'debug#index', as: :debug
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
