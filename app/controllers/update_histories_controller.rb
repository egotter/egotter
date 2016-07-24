class UpdateHistoriesController < ApplicationController
  include SearchesHelper

  before_action :set_twitter_user, only: %i(show)

  # GET /update_histories/:id
  def show
    @title = t('search_menu.update_histories', user: @searched_tw_user.mention_name)
    @update_histories = UpdateHistories.new(@searched_tw_user.uid)
  end
end
