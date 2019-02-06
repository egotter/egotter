class SearchHistoriesController < ApplicationController
  def new
    render partial: 'twitter/user', collection: latest_search_histories, cached: true, locals: {ad: false, via: 'search_histories'}
  end
end
