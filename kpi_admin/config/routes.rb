KpiAdmin::Engine.routes.draw do
  root to: "kpis#index"
  resources :kpis, only: :index
end
