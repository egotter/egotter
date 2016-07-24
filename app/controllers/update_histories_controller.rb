class UpdateHistoriesController < ApplicationController
  include Logging
  include SearchesHelper

  before_action :set_twitter_user, only: %i(show)
  before_action only: %i(show) do
    create_search_log(action: :update_histories)
  end

  # GET /update_histories/:id
  def show
    @title = t('search_menu.update_histories', user: @searched_tw_user.mention_name)
    @update_histories = UpdateHistories.new(@searched_tw_user.uid)
  end
end
