class TimelinesController < ApplicationController

  before_action { reject_spam_access! }

  include JobQueueingConcern
  include SearchRequestConcern
  include SanitizationConcern

  before_action(only: :waiting) { valid_screen_name? }

  before_action do
    enqueue_update_authorized
    enqueue_update_egotter_friendship
  end

  after_action { UsageCount.increment }

  def show
  end

  def waiting
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user

    @redirect_path = sanitized_redirect_path(params[:redirect_path] || timeline_path(screen_name: params[:screen_name], via: current_via))
    @screen_name = params[:screen_name]
  end
end
