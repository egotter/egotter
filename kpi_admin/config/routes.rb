KpiAdmin::Engine.routes.draw do
  root to: 'kpis#index'
  resources :kpis, only: :index
  %i(one two table rr).each do |name|
    get name, to: "kpis##{name}", as: name
  end
end
