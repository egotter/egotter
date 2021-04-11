class TimelinesController < ApplicationController

  before_action :reject_spam_access!

  include JobQueueingConcern
  include SearchRequestConcern
  include SanitizationConcern

  before_action :valid_screen_name?, only: :waiting
  before_action :not_found_screen_name?, only: :waiting
  before_action :forbidden_screen_name?, only: :waiting
  before_action :set_user, only: :waiting

  before_action :enqueue_update_authorized, only: :show
  before_action :enqueue_update_egotter_friendship, only: :show

  after_action(only: :show) { UsageCount.increment }

  def show
  end

  def waiting
    @redirect_path = sanitized_redirect_path(params[:redirect_path] || timeline_path(screen_name: params[:screen_name], via: current_via))
    @screen_name = params[:screen_name]
  end

  private

  def set_user
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user
  end
end
