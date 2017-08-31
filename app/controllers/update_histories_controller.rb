class UpdateHistoriesController < ApplicationController
  include Concerns::Validation
  include SearchesHelper

  before_action(only: %i(show)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { twitter_user_persisted?(params[:uid].to_i) }
  before_action(only: %i(show)) { @twitter_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: %i(show)) { authorized_search?(@twitter_user) }
  before_action only: %i(show) do
    push_referer
    create_search_log
  end

  def show
    @title = t('update_histories.show.short_title', user: @twitter_user.mention_name)
    @update_histories = UpdateHistories.new(@twitter_user.uid)
  end
end
