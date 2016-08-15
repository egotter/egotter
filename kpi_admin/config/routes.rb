KpiAdmin::Engine.routes.draw do
  root to: 'kpis#index'
  resources :kpis, only: :index
  %i(dau daily_search_num daily_new_user daily_sign_in
     mau
     table rr).each do |name|
    get name, to: "kpis##{name}", as: name
  end
end
