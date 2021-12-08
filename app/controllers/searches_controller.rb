class SearchesController < ApplicationController
  include JobQueueingConcern
  include SanitizationConcern
  include SearchHistoriesConcern
  include PathsHelper
  include SearchRequestCreation

  before_action :reject_crawler
  before_action :valid_screen_name?
  before_action :not_found_screen_name?
  before_action :forbidden_screen_name?
  before_action :find_or_create_search_request

  before_action { create_search_history(@twitter_user) }

  def create
    redirect_path = sanitized_redirect_path(params[:redirect_path].presence || timeline_path(@twitter_user, via: current_via))
    redirect_path.sub!(':screen_name', @twitter_user.screen_name) if redirect_path.include?(':screen_name')

    if TwitterUser.with_delay.exists?(uid: @twitter_user.uid)
      redirect_to redirect_path
    else
      jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, force: true)
      redirect_to waiting_path(uid: @twitter_user.uid, redirect_path: redirect_path, jid: jid, via: current_via)
    end
  end
end
