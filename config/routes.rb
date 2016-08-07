Rails.application.routes.draw do
  root 'searches#new'

  if ENV['MAINTENANCE'] == '1'
    match '*path' => 'misc#maintenance', via: :all
  end

  %i(maintenance privacy_policy terms_of_service sitemap menu support).each do |name|
    get name, to: "misc##{name}", as: name
  end
  patch 'menu', to: 'misc#menu'

  resources :searches, only: %i(new create show)
  get 'searches/:screen_name/waiting', to: 'searches#waiting', as: :waiting
  resources :search_results, only: :show

  %i(friends followers removing removed blocking_or_blocked one_sided_friends one_sided_followers
    mutual_friends common_friends common_followers replying replied favoriting inactive_friends
    inactive_followers clusters_belong_to close_friends usage_stats).each do |name|
    get "searches/:screen_name/#{name}", to: "searches##{name}", as: name
  end

  %i(statuses update_histories).each do |name|
    get "searches/:screen_name/#{name}", to: 'searches#debug'
  end
  %i(searches twitegosearch/list).each do |name|
    get name, to: 'searches#debug'
  end
  get 'search', to: 'searches#debug'
  post 'searches/:screen_name/waiting', to: 'searches#debug'

  resources :search_histories, only: :index
  resources :information, only: :index
  resources :notifications, only: :index
  resources :statuses, only: :show
  get 'keyword_timeline', to: 'statuses#keyword_timeline', as: :keyword_timeline
  resources :update_histories, only: :show
  resources :background_search_logs, only: %i(index show)
  resources :page_caches, only: %i(create destroy)
  post 'clear_result_cache', to: 'page_caches#clear', as: :clear_result_cache

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

  resources :kpis, only: :index
  %i(dau search_num new_user sign_in table rr).each do |name|
    get "kpis/#{name}", to: "kpis##{name}", as: "kpis_#{name}"
  end
  get 'debug', to: 'debug#index', as: :debug
end
