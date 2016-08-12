Rails.application.routes.draw do
  mount KpiAdmin::Engine => "/kpis"
end
