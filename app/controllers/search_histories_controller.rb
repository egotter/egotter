class SearchHistoriesController < ApplicationController
  def new
    render partial: 'twitter/user', collection: current_search_histories, cached: true, locals: {grid_class: 'col-xs-12', ad: false, via: 'search_histories'}
  end
end
