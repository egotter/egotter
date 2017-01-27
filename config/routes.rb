Rails.application.routes.draw do
  if ENV['MAINTENANCE'] == '1'
    root 'misc#maintenance'
    match '*path' => 'misc#maintenance', via: :all
  else
    root 'searches#new'
  end

  %i(maintenance privacy_policy terms_of_service sitemap menu support).each do |name|
    get name, to: "misc##{name}", as: name
  end

  resources :one_sided_friends, only: %i(create show), param: :screen_name
  get 'one_sided_friends', to: 'one_sided_friends#new', as: :one_sided_friends_top
  get 'one_sided_followers', to: 'one_sided_followers#new', as: :one_sided_followers_top

  resources :unfriends, only: %i(create show), param: :screen_name
  get 'unfriends', to: 'unfriends#new', as: :unfriends_top

  resources :searches, only: %i(create), param: :screen_name do
    Search::MENU.each { |menu| get menu, on: :member }
  end
  resources :searches, only: %i(show), param: :screen_name
  get 'searches/:uid/waiting', to: 'searches#waiting', as: :waiting_search

  resources :search_results, only: :show, param: :uid do
    Search::MENU.each { |menu| get menu, on: :member }
  end

  resources :search_histories, :information, :notifications, only: :index
  resource :notification, only: :update

  resources :statuses, only: :show, param: :uid
  get 'keyword_timeline', to: 'statuses#keyword_timeline', as: :keyword_timeline

  resources :update_histories, only: :show, param: :uid
  resources :background_search_logs, only: :show, param: :uid
  resources :modal_open_logs, only: :create
  resources :polling_logs, only: :create
  resources :page_caches, only: %i(create destroy), param: :uid

  resources :relationships, only: %i(create)
  get 'relationships/:src_uid/:dst_uid/waiting', to: 'relationships#waiting', as: :waiting_relationship
  get 'relationships/:src_uid/:dst_uid/check_log', to: 'relationships#check_log', as: :check_log_relationship
  %w(conversations common_friends common_followers).each do |type|
    get "#{type}/:src_screen_name/:dst_screen_name", to: "relationships##{type}", as: type.singularize
  end

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

  %i(statuses update_histories).each do |name|
    get "searches/:screen_name/#{name}", to: 'searches#debug'
  end
  %i(twitegosearch twitegosearch/list twitegosearch/profile search searches caches page_cache page_caches).each do |name|
    get name, to: 'searches#debug'
  end

  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end if Rails.env.production?
  mount Sidekiq::Web, at: '/sidekiq'

  if defined?(Blazer::Engine)
    mount Blazer::Engine, at: '/blazer'
  end
end
