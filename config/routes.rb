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
      Search::API_V1_NAMES.each do |menu|
        get "#{menu}/summary", to: "#{menu}#summary"
        get "#{menu}/list", to: "#{menu}#list"
      end

      # TODO Remove later
      get "blocking_or_blocked/summary", to: "mutual_unfriends#summary"
      get "blocking_or_blocked/list", to: "mutual_unfriends#list"

      get "close_friends", to: "close_friends#show"
      get "word_clouds", to: "word_clouds#show"
      get "friend_insights/profiles_count", to: "friend_insights#profiles_count"
      get "friend_insights/locations_count", to: "friend_insights#locations_count"
      get "friend_insights/tweet_times", to: "friend_insights#tweet_times"
      get "follower_insights/profiles_count", to: "follower_insights#profiles_count"
      get "follower_insights/locations_count", to: "follower_insights#locations_count"
      get "follower_insights/tweet_times", to: "follower_insights#tweet_times"
      get "trends/words_count", to: "trends#words_count"
      get "trends/profile_words_count", to: "trends#profile_words_count"
      get "trends/times_count", to: "trends#times_count"
      get "trends/users_count", to: "trends#users_count"

      get "timelines", to: "timelines#show"
      get "summaries", to: "summaries#show"
      get "profiles", to: "profiles#show"
      get 'account_statuses', to: 'account_statuses#show'
      get 'search_requests', to: 'search_requests#show'
      get "announcements/list", to: "announcements#list"
      get "features/list", to: "features#list"
      get "functions/list", to: "functions#list"

      post 'users/update_instance_id', to: 'users#update_instance_id'
      post 'users/update_device_token', to: 'users#update_device_token'
      post 'bots/invalidate_expired_credentials', to: 'bots#invalidate_expired_credentials'
      post 'metrics/send_to_cloudwatch', to: 'metrics#send_to_cloudwatch'
      post 'not_found_users/delete', to: 'not_found_users#delete'
      post 'forbidden_users/delete', to: 'forbidden_users#delete'
      post 'periodic_report_settings', to: 'periodic_report_settings#update'
      post 'create_periodic_tweet_requests', to: 'create_periodic_tweet_requests#update'
      post 'orders/end_trial', to: 'orders#end_trial'
      post 'orders/cancel', to: 'orders#cancel'
      resources :share_tweets, only: %i(create)

      resources :follow_requests, only: %i(create)

      resources :close_friends_og_images, only: %i(show), param: :uid

      resource :sneak_search_requests, only: %i(create destroy)
      resource :private_mode_settings, only: %i(create destroy)
      resources :delete_tweets_requests, only: %i(create)
      resources :delete_tweets_notifications, only: %i(create)
      resources :delete_tweets_presigned_urls, only: %i(create)
      post "delete_favorites", to: "delete_favorites#destroy"

      resources :checkout_sessions, only: %i(create)
      resources :customer_portal_urls, only: %i(create)
      delete 'user_caches', to: 'user_caches#destroy'
      delete 'user_data', to: 'user_data#destroy'

      resources :friend_ids, only: %i(create)
      resources :follower_ids, only: %i(create)
    end
  end

  get 'error_pages/too_many_searches', to: 'error_pages#too_many_searches'
  get 'error_pages/ad_blocker_detected', to: 'error_pages#ad_blocker_detected'
  get 'error_pages/soft_limited', to: 'error_pages#soft_limited'
  get 'error_pages/not_found_user', to: 'error_pages#not_found_user'
  get 'error_pages/forbidden_user', to: 'error_pages#forbidden_user'
  get 'error_pages/not_signed_in', to: 'error_pages#not_signed_in'
  get 'error_pages/spam_ip_detected', to: 'error_pages#spam_ip_detected'
  get 'error_pages/suspicious_access_detected', to: 'error_pages#suspicious_access_detected'
  get 'error_pages/twitter_user_not_persisted', to: 'error_pages#twitter_user_not_persisted'
  get 'error_pages/secret_mode_detected', to: 'error_pages#secret_mode_detected'

  get 'l/:name', to: 'landing_pages#new'

  get 'delete_tweets', to: 'delete_tweets#new'
  get 'delete_tweets/mypage', to: 'delete_tweets#show', as: :delete_tweets_mypage

  get 'delete_favorites', to: 'delete_favorites#new'
  get 'delete_favorites/mypage', to: 'delete_favorites#show', as: :delete_favorites_mypage

  namespace :directory do
    get "profiles(/:id1(/:id2))", to: "profiles#show", as: :profile
    get "timelines(/:id1(/:id2))", to: "timelines#show", as: :timeline
  end

  %i(maintenance privacy_policy terms_of_service specified_commercial_transactions support).each do |name|
    get name, to: "misc##{name}", as: name
  end

  %i(
    profiles
    friends
    followers
    statuses
    audience_insights
    close_friends
    favorite_friends
    usage_stats
    unfriends
    unfollowers
    mutual_unfriends
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
  resources 'access_confirmations', only: %i(index)
  resources 'follow_confirmations', only: %i(index)
  resources 'blockers', only: %i(index)
  resources 'trends', only: %i(index)
  get 'trends/:id/tweets', to: 'trends#tweets', as: 'trend_tweets'
  get 'trends/:id/media', to: 'trends#media', as: 'trend_media'
  get 'trends/:id', to: 'trends#show', as: 'trend'
  get 'trends/:id/download_tweets', to: 'trends#download_tweets', as: 'trend_download_tweets'

  get 'blocking_or_blocked/:screen_name', to: redirect("/mutual_unfriends/%{screen_name}?via=routing")

  get "friends/:screen_name/download", to: "friends#download", as: :friend_download
  get "followers/:screen_name/download", to: "followers#download", as: :follower_download
  get "mutual_friends/:screen_name/download", to: "mutual_friends#download", as: :mutual_friend_download
  get "one_sided_friends/:screen_name/download", to: "one_sided_friends#download", as: :one_sided_friend_download
  get "one_sided_followers/:screen_name/download", to: "one_sided_followers#download", as: :one_sided_follower_download
  get "inactive_mutual_friends/:screen_name/download", to: "inactive_mutual_friends#download", as: :inactive_mutual_friend_download
  get "inactive_friends/:screen_name/download", to: "inactive_friends#download", as: :inactive_friend_download
  get "inactive_followers/:screen_name/download", to: "inactive_followers#download", as: :inactive_follower_download
  get "mutual_unfriends/:screen_name/download", to: "mutual_unfriends#download", as: :mutual_unfriend_download
  get "unfriends/:screen_name/download", to: "unfriends#download", as: :unfriend_download
  get "unfollowers/:screen_name/download", to: "unfollowers#download", as: :unfollower_download

  get 'profiles/:screen_name/latest', to: redirect("/profiles/%{screen_name}")

  %i(
    friends
    followers
    close_friends
    favorite_friends
    unfriends
    unfollowers
    mutual_unfriends
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
    get "#{controller_name}/:screen_name/all", to: redirect("/#{controller_name}/%{screen_name}")
  end
  match 'statuses/:screen_name/oembed' => proc { [404, {'Content-Type' => 'text/plain'}, ''] }, via: :get

  get 'close_friends', to: 'close_friends#new', as: :close_friends_top
  get 'one_sided_friends', to: 'one_sided_friends#new', as: :one_sided_friends_top
  get 'unfriends', to: 'unfriends#new', as: :unfriends_top
  get 'inactive_friends', to: 'inactive_friends#new', as: :inactive_friends_top
  get 'friends', to: 'friends#new', as: :friends_top

  resources :word_clouds, only: %i(show), param: :screen_name

  resources :clusters, only: %i(show), param: :screen_name
  get 'clusters', to: 'clusters#new', as: :clusters_top

  resources :personality_insights, only: %i(show), param: :screen_name
  get 'personality_insights', to: 'personality_insights#new', as: :personality_insights_top

  resources :searches, only: %i(create), param: :screen_name
  get 'waiting/:uid', to: 'waiting#new', as: :waiting

  resources :twitter_users, only: %i(show), param: :uid
  get 'twitter_users/:uid/changes', to: 'twitter_users#changes', as: :twitter_users_changes

  resources :timelines, only: %i(show), param: :screen_name
  get 'timelines/:screen_name/waiting', to: 'timelines#waiting', as: :timeline_waiting

  get 'not_found/:screen_name', to: redirect("/profiles/%{screen_name}?via=routing_not_found"), as: 'not_found'
  get 'not_found/:screen_name/latest', to: redirect("/profiles/%{screen_name}?via=routing_not_found")
  get 'forbidden/:screen_name', to: redirect("/profiles/%{screen_name}?via=routing_forbidden"), as: 'forbidden'
  get 'forbidden/:screen_name/latest', to: redirect("/profiles/%{screen_name}?via=routing_forbidden")
  get 'blocked/:screen_name', to: redirect("/profiles/%{screen_name}?via=routing_blocked"), as: 'blocked'
  get 'blocked/:screen_name/latest', to: redirect("/profiles/%{screen_name}?via=routing_blocked")
  get 'protected/:screen_name', to: redirect("/profiles/%{screen_name}?via=routing_protected"), as: 'protected'
  get 'protected/:screen_name/latest', to: redirect("/profiles/%{screen_name}?via=routing_protected")

  resources :unfollows, only: %i(create)

  get 'tokimeki_unfollow', to: 'tokimeki_unfollow#new', as: :tokimeki_unfollow_top
  get 'tokimeki_unfollow/cleanup', to: 'tokimeki_unfollow#cleanup', as: :tokimeki_unfollow_cleanup
  post 'tokimeki_unfollow/unfollow', to: 'tokimeki_unfollow#unfollow', as: :tokimeki_unfollow_unfollow
  post 'tokimeki_unfollow/keep', to: 'tokimeki_unfollow#keep', as: :tokimeki_unfollow_keep

  resources :settings, only: :index
  get 'settings/follow_requests', to: "settings#follow_requests"
  get 'settings/unfollow_requests', to: "settings#unfollow_requests"
  resources :diagnosis, only: :index

  get 'pricing', to: "pricing#new"
  resources :orders, only: %i(create)
  get 'orders/success', to: "orders#success"
  get 'orders/failure', to: "orders#failure"
  get 'orders/cancel', to: "orders#cancel"
  post 'orders/checkout_session_completed', to: "orders#checkout_session_completed"

  get 'webhook/twitter', to: 'webhook#challenge'
  post 'webhook/twitter', to: 'webhook#twitter'

  get 'adsense', to: 'adsense#new'
  get 'search_histories', to: 'search_histories#new'
  get 'load_public_tweets', to: 'public_tweets#load', as: :load_public_tweets

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

  namespace :api, {format: 'json'} do
    namespace :v1 do
      get 'report_stats', to: 'report_stats#index'
      get 'access_stats', to: 'access_stats#index'
    end
  end

  get 'app_stats', to: 'app_stats#index'

  require 'sidekiq/web'
  if Rails.env.production?
    authenticate :user, lambda { |u| [User::ADMIN_UID, User::EGOTTER_UID].include?(u.uid) } do
      mount Sidekiq::Web => '/sidekiq'
      mount Blazer::Engine, at: '/blazer' if defined?(Blazer::Engine)
    end
  elsif Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
    mount Blazer::Engine, at: '/blazer'
  end

  mount Ahoy::Engine => '/ahoy'

  match '*unmatched_route', to: 'application#not_found', via: :all
end
