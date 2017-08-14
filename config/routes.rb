Rails.application.routes.draw do
  if ENV['MAINTENANCE'] == '1'
    root 'misc#maintenance'
    match '*path' => 'misc#maintenance', via: :all
  else
    root 'searches#new'
  end

  namespace :api, {format: 'json'} do
    namespace :v1 do
      Search::API_V1_NAMES.each {|menu| get "#{menu}/summary", to: "#{menu}#summary"}
      Search::API_V1_NAMES.each {|menu| get "#{menu}/list", to: "#{menu}#list"}
    end
  end

  %i(maintenance privacy_policy terms_of_service sitemap support).each do |name|
    get name, to: "misc##{name}", as: name
  end
  get '/menu', to: redirect('/settings')

  %i(friends followers statuses close_friends scores usage_stats unfriends unfollowers blocking_or_blocked).each do |controller_name|
    resources controller_name, only: %i(show), param: :screen_name
  end
  match 'statuses/:screen_name/oembed' => proc { [404, {'Content-Type' => 'text/plain'}, ''] }, via: :get

  resources :one_sided_friends, only: %i(create show), param: :screen_name
  get 'one_sided_friends', to: 'one_sided_friends#new', as: :one_sided_friends_top

  get 'unfriends', to: 'unfriends#new', as: :unfriends_top

  resources :inactive_friends, only: %i(create show), param: :screen_name
  get 'inactive_friends', to: 'inactive_friends#new', as: :inactive_friends_top

  get 'friends', to: 'friends#new', as: :friends_top

  resources :conversations, only: %i(create show), param: :screen_name
  get 'conversations', to: 'conversations#new', as: :conversations_top

  resources :clusters, only: %i(create show), param: :screen_name
  get 'clusters', to: 'clusters#new', as: :clusters_top

  resources :searches, only: %i(create), param: :screen_name do
    get 'favoriting', on: :member
  end
  %i(
      close_friends
      usage_stats
      inactive_friends
      inactive_followers
      friends
      followers
    ).each { |menu| get "/searches/:screen_name/#{menu}", to: redirect("/#{menu}/%{screen_name}") }
  %w(
      new_friends
      new_followers
    ).each { |menu| get "/searches/:screen_name/#{menu}", to: redirect("/#{menu.remove('new_')}/%{screen_name}") }
  get '/searches/:screen_name/clusters_belong_to', to: redirect('/clusters/%{screen_name}')

  resources :searches, only: %i(show), param: :screen_name
  get '/searches/:screen_name', to: redirect('/timelines/%{screen_name}')
  get 'searches/:uid/waiting', to: 'searches#waiting', as: :waiting_search
  match 'searches/:screen_name/force_update' => proc { [404, {'Content-Type' => 'text/plain'}, ''] }, via: :post
  match 'searches/:uid/force_reload' => proc { [404, {'Content-Type' => 'text/plain'}, ''] }, via: :post

  resources :search_results, only: [], param: :uid do
    %i(favoriting).each { |menu| get menu, on: :member }
  end

  resources :timelines, only: %i(show), param: :screen_name
  get 'timelines/:uid/check_for_updates', to: 'timelines#check_for_updates', as: :check_for_updates
  get 'timelines/:uid/check_for_follow', to: 'timelines#check_for_follow', as: :check_for_follow

  resources :notifications, only: :index
  resources :settings, only: :index
  resource :setting, only: :update

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

  %i(sign_in sign_out welcome goodbye).each do |name|
    get name, to: "login##{name}", as: name
  end

  devise_for :users, skip: [:sessions, :registrations, :password], controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  as :user do
    get '/_sign_out' => 'devise/sessions#destroy', :as => :destroy_user_session
    get '/' => 'devise/sessions#new', :as => :new_user_session
  end

  require 'sidekiq/api'
  match 'delay_status' => proc {
    q1 = Sidekiq::Queue.new(DelayedCreateTwitterUserWorker.name)
    q2 = Sidekiq::Queue.new(DelayedImportTwitterUserRelationsWorker.name)
    [200, {'Content-Type' => 'text/plain'}, ["#{q1.size} #{q2.size}"]]
  }, via: :get

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
