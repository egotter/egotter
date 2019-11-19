class SearchesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SanitizationConcern
  include PathsHelper

  before_action :reject_crawler
  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
  before_action { !protected_search?(@twitter_user) && !blocked_search?(@twitter_user) }
  before_action { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) }

  before_action do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def create
    CreateSearchHistoryWorker.perform_async(fingerprint, current_user_id, @twitter_user.uid, current_visit&.id, via: params[:via])

    redirect_path = sanitized_redirect_path(params[:redirect_path].presence || timeline_path(@twitter_user))

    if TwitterUser.exists?(uid: @twitter_user.uid)
      redirect_to redirect_path
    else
      jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, requested_by: 'search')
      redirect_to waiting_path(uid: @twitter_user.uid, redirect_path: redirect_path, jid: jid, via: build_via)
    end
  end
end
