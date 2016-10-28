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

  resources :searches, only: %i(new create show)
  get 'searches/:id/waiting', to: 'searches#waiting', as: :waiting
  resources :search_results, only: :show

  Search::MENU.each do |menu|
    get "searches/:screen_name/#{menu}", to: "searches##{menu}", as: menu
    get "search_results/:id/#{menu}", to: "search_results##{menu}", as: "#{menu}_results"
  end

  %i(statuses update_histories).each do |name|
    get "searches/:screen_name/#{name}", to: 'searches#debug'
  end
  %i(twitegosearch twitegosearch/list twitegosearch/profile).each do |name|
    get name, to: 'searches#debug'
  end
  get 'search', to: 'searches#debug'

  resources :search_histories, only: :index
  resources :information, only: :index
  resources :notifications, only: :index
  patch 'notification', to: 'notifications#update'
  resources :statuses, only: :show
  get 'keyword_timeline', to: 'statuses#keyword_timeline', as: :keyword_timeline
  resources :update_histories, only: :show
  resources :background_search_logs, only: %i(show)
  resources :modal_open_logs, only: %i(create)
  resources :page_caches, only: %i(create destroy)

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
