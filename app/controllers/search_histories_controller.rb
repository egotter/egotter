class SearchHistoriesController < ApplicationController
  def new
    users = current_search_histories.map(&:twitter_db_user).compact

    # Don't specify cached: true because wrong data (duplicate records are removed?) is cached.
    render partial: 'twitter/user', collection: users, locals: {grid_class: 'col-xs-12', ad: false, via: 'search_histories'}
  end
end
