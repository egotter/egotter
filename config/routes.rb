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

  resources :unfriends, only: %i(create show), param: :screen_name
  get 'unfriends', to: 'unfriends#new', as: :unfriends_top

  resources :inactive_friends, only: %i(create show), param: :screen_name
  get 'inactive_friends', to: 'inactive_friends#new', as: :inactive_friends_top

  resources :friends, only: %i(create show), param: :screen_name
  get 'friends', to: 'friends#new', as: :friends_top

  resources :conversations, only: %i(create show), param: :screen_name
  get 'conversations', to: 'conversations#new', as: :conversations_top

  resources :searches, only: %i(create), param: :screen_name do
    Search::MENU.each { |menu| get menu, on: :member }
  end
  resources :searches, only: %i(show), param: :screen_name
  get 'searches/:uid/waiting', to: 'searches#waiting', as: :waiting_search

  resources :search_results, only: :show, param: :uid do
    %i(new_friends new_followers favoriting close_friends clusters_belong_to usage_stats).each { |menu| get menu, on: :member }
  end

  resources :search_histories, :notifications, only: :index
  resource :notification, only: :update

  resources :statuses, only: :show, param: :uid

  resources :update_histories, only: :show, param: :uid
  resources :background_search_logs, only: :show, param: :uid
  resources :modal_open_logs, only: :create
  resources :polling_logs, only: :create
  resources :page_caches, only: %i(create destroy), param: :uid

  resources :relationships, only: %i(create)
  get 'relationships/:src_uid/:dst_uid/waiting', to: 'relationships#waiting', as: :waiting_relationship
  get 'relationships/:src_uid/:dst_uid/check_log', to: 'relationships#check_log', as: :check_log_relationship
  get 'relationships/:src_screen_name/:dst_screen_name', to: 'relationships#show', as: :relationship
  get 'relationships', to: 'relationships#new', as: :relationships_top

  %i(sign_in sign_out welcome).each do |name|
    get name, to: "login##{name}", as: name
  end

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

  if defined?(Blazer::Engine)
    mount Blazer::Engine, at: '/blazer'
  end

  get '*unmatched_route', to: 'application#not_found'
end
