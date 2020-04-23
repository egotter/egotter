Rails.application.routes.draw do
  if ENV['MAINTENANCE'] == '1'
    root 'misc#maintenance'
    match '*path' => 'misc#maintenance', via: :all
  else
    root 'home#new'
    get 'start', to: 'home#start', as: 'start'
  end

  namespace :api, {format: 'json'} do
    namespace :v1 do
      Search::API_V1_NAMES.each { |menu| get "#{menu}/summary", to: "#{menu}#summary" }
      Search::API_V1_NAMES.each { |menu| get "#{menu}/list", to: "#{menu}#list" }

      post 'users/update_instance_id', to: 'users#update_instance_id'
      post 'users/update_device_token', to: 'users#update_device_token'
    end
  end

  get 'delete_tweets', to: 'delete_tweets#new'
  get 'delete_tweets/mypage', to: 'delete_tweets#show', as: :delete_tweets_mypage
  post "delete_tweets", to: "delete_tweets#delete"

  delete "reset_egotter", to: "reset_egotter#reset"
  post "reset_cache", to: "reset_cache#reset"

  namespace :directory do
    get "profiles(/:id1(/:id2))", to: "profiles#show", as: :profile
    get "timelines(/:id1(/:id2))", to: "timelines#show", as: :timeline
  end

  %i(maintenance privacy_policy terms_of_service specified_commercial_transactions support).each do |name|
    get name, to: "misc##{name}", as: name
  end
  get '/menu', to: redirect('/settings?via=routing_menu')

  %i(
    profiles
    friends
    followers
    statuses
    audience_insights
    close_friends
    favorite_friends
    scores
    usage_stats
    unfriends
    unfollowers
    blocking_or_blocked
    inactive_friends
    inactive_followers
    inactive_mutual_friends
    one_sided_friends
    one_sided_followers
    mutual_friends
    replying
    replied
    replying_and_replied
    common_friends
    common_followers
    common_mutual_friends
  ).each do |controller_name|
    resources controller_name, only: %i(show), param: :screen_name
  end

  get 'profiles/:screen_name/latest', to: 'profiles#latest', as: 'latest_profile'

  %i(
    friends
    followers
    close_friends
    favorite_friends
    unfriends
    unfollowers
    blocking_or_blocked
    inactive_friends
    inactive_followers
    inactive_mutual_friends
    one_sided_friends
    one_sided_followers
    mutual_friends
    replying
    replied
    replying_and_replied
    common_friends
    common_followers
    common_mutual_friends
  ).each do |controller_name|
    get "#{controller_name}/:screen_name/all", to: "#{controller_name}#all", as: "all_#{controller_name}"
  end
  match 'statuses/:screen_name/oembed' => proc { [404, {'Content-Type' => 'text/plain'}, ''] }, via: :get

  get 'one_sided_friends', to: 'one_sided_friends#new', as: :one_sided_friends_top
  get 'unfriends', to: 'unfriends#new', as: :unfriends_top
  get 'inactive_friends', to: 'inactive_friends#new', as: :inactive_friends_top
  get 'friends', to: 'friends#new', as: :friends_top
  get 'conversations', to: redirect('/')
  get 'relationships', to: redirect('/')

  resources :clusters, only: %i(create show), param: :screen_name
  get 'clusters', to: 'clusters#new', as: :clusters_top

  get '/searches/:screen_name/favoriting', to: redirect('/favorite_friends/%{screen_name}')
  %i(
      close_friends
      usage_stats
      inactive_friends
      friends
      followers
      blocking_or_blocked
    ).each { |menu| get "/searches/:screen_name/#{menu}", to: redirect("/#{menu}/%{screen_name}") }
  get '/searches/:screen_name/inactive_followers', to: redirect('/inactive_friends/%{screen_name}')
  %w(
      new_friends
      new_followers
    ).each { |menu| get "/searches/:screen_name/#{menu}", to: redirect("/#{menu.remove('new_')}/%{screen_name}") }
  get '/searches/:screen_name/clusters_belong_to', to: redirect('/clusters/%{screen_name}')

  resources :searches, only: %i(create), param: :screen_name
  get '/searches/:screen_name', to: redirect('/timelines/%{screen_name}')
  get 'searches/:uid/waiting', to: redirect('/waiting/%{uid}')
  get 'waiting/:uid', to: 'waiting#new', as: :waiting

  resources :account_statuses, only: %i(show), param: :uid
  resources :twitter_users, only: %i(create show), param: :uid
  get 'twitter_users/:uid/changes', to: 'twitter_users#changes', as: :twitter_users_changes

  resources :timelines, only: %i(show), param: :screen_name

  resources :not_found, only: %i(show), param: :screen_name
  get 'not_found/:screen_name/latest', to: 'not_found#latest', as: 'latest_not_found'
  resources :forbidden, only: %i(show), param: :screen_name
  get 'forbidden/:screen_name/latest', to: 'forbidden#latest', as: 'latest_forbidden'
  resources :blocked, only: %i(show), param: :screen_name
  get 'blocked/:screen_name/latest', to: 'blocked#latest', as: 'latest_blocked'
  resources :protected, only: %i(show), param: :screen_name
  get 'protected/:screen_name/latest', to: 'protected#latest', as: 'latest_protected'

  get 'follow', to: 'follows#show'
  resources :follows, only: %i(create)
  resources :unfollows, only: %i(create)
  resources :shares, only: %i(create)

  get 'usage_stats/:uid/check_for_updates', to: 'usage_stats#check_for_updates', as: :check_for_updates_usage_stat

  get 'tokimeki_unfollow', to: 'tokimeki_unfollow#new', as: :tokimeki_unfollow_top
  get 'tokimeki_unfollow/cleanup', to: 'tokimeki_unfollow#cleanup', as: :tokimeki_unfollow_cleanup
  post 'tokimeki_unfollow/unfollow', to: 'tokimeki_unfollow#unfollow', as: :tokimeki_unfollow_unfollow
  post 'tokimeki_unfollow/keep', to: 'tokimeki_unfollow#keep', as: :tokimeki_unfollow_keep

  get 'notifications', to: redirect('/?notifications_not_found=1')
  resources :settings, only: :index
  resource :setting, only: :update
  post 'settings/update_report_interval', to: 'settings#update_report_interval', as: :update_report_interval
  get 'settings/follow_requests', to: "settings#follow_requests"
  get 'settings/unfollow_requests', to: "settings#unfollow_requests"
  get 'settings/create_prompt_requests', to: "settings#create_prompt_report_requests"
  get 'settings/create_test_requests', to: "settings#create_test_report_requests"
  get 'settings/twitter_users', to: "settings#twitter_users"

  namespace :admin do
    get "settings/:user_id/follow_requests", to: "settings#follow_requests"
    get "settings/:user_id/unfollow_requests", to: "settings#unfollow_requests"
    get "settings/:user_id/create_prompt_report_requests", to: "settings#create_prompt_report_requests"
  end

  get 'pricing', to: "pricing#new"
  resources :orders, only: %i(create destroy)
  get 'orders/success', to: "orders#success"
  get 'orders/cancel', to: "orders#cancel"
  post 'orders/checkout_session_completed', to: "orders#checkout_session_completed"

  get 'webhook/twitter', to: 'webhook#challenge'
  post 'webhook/twitter', to: 'webhook#twitter'

  get 'update_histories/:uid', to: redirect('/settings?via=routing_update_histories')

  get 'adsense', to: 'adsense#new'
  get 'search_histories', to: 'search_histories#new'
  get 'load_public_tweets', to: 'public_tweets#load', as: :load_public_tweets

  get 'relationships/:src_uid/:dst_uid/waiting', to: redirect('/')
  get 'relationships/:src_uid/:dst_uid/check_log', to: redirect('/')
  get 'relationships/:src_screen_name/:dst_screen_name', to: redirect('/')

  %i(sign_in after_sign_in after_sign_up goodbye).each do |name|
    get name, to: "login##{name}", as: name
  end
  delete :sign_out, to: "login#sign_out", as: :sign_out
  get 'welcome', to: "welcome#new"

  get 'search_count', to: 'search_count#new'

  devise_for :users, skip: %i(sessions confirmations registrations passwords unlocks), controllers: {omniauth_callbacks: 'users/omniauth_callbacks'}
  devise_scope :user do
    get '_sign_out' => 'users/sessions#destroy', :as => :destroy_user_session
  end

  require 'sidekiq/api'
  match 'delay_status' => proc {
    q1 = Sidekiq::Queue.new(DelayedCreateTwitterUserWorker.name)
    q2 = Sidekiq::Queue.new(DelayedImportTwitterUserRelationsWorker.name)
    [200, {'Content-Type' => 'text/plain'}, ["#{q1.size} #{q2.size}"]]
  }, via: :get

  require 'sidekiq/web'
  if Rails.env.production?
    authenticate :user, lambda { |u| [User::ADMIN_UID, User::EGOTTER_UID].include?(u.uid) } do
      mount Sidekiq::Web => '/sidekiq'
      mount Blazer::Engine, at: '/blazer' if defined?(Blazer::Engine)
    end
  else
    mount Sidekiq::Web => '/sidekiq'
    mount Blazer::Engine, at: '/blazer'
  end

  match '*unmatched_route', to: 'application#not_found', via: :all
end
