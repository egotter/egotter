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
  resources :page_caches, only: %i(create destroy), param: :uid

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

  if defined?(KpiAdmin::Engine)
    KpiAdmin::Engine.use Rack::Auth::Basic do |username, password|
      username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
    end if Rails.env.production?
    mount KpiAdmin::Engine, at: '/kpis', as: :kpis
  end
end
