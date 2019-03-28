class SearchHistoriesController < ApplicationController
  def new
    users = current_search_histories.map(&:twitter_db_user)
    render partial: 'twitter/user', collection: users, cached: true, locals: {grid_class: 'col-xs-12', ad: false, via: 'search_histories'}
  end
end
