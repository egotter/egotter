class TwitterUsersController < ApplicationController
  include WorkersHelper

  before_action :reject_crawler
  before_action { valid_uid?(params[:uid].to_i) }
  before_action { @twitter_user = build_twitter_user_by(uid: params[:uid].to_i) }
  before_action { authorized_search?(@twitter_user) && !blocked_search?(@twitter_user) }
  before_action { !too_many_searches?(@twitter_user) }
  before_action do
    # As a transitory measure
    # !too_many_requests?(@twitter_user)
  end

  before_action { create_search_log }

  def create
    jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, screen_name: @twitter_user.screen_name)
    render json: {uid: @twitter_user.uid, screen_name: @twitter_user.screen_name, jid: jid}
  end
end
