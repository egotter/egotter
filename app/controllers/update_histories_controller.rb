class UpdateHistoriesController < ApplicationController
  include SearchesHelper

  before_action :set_twitter_user, only: %i(show)

  # GET /update_histories/:id
  def show
    @update_histories = TwitterUser.where(uid: @searched_tw_user.uid).order(created_at: :desc)
  end
end
