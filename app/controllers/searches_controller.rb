class SearchesController < ApplicationController
  include WorkersHelper

  before_action :reject_crawler
  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
  # You must call blocked_search? after you call authorized_search?
  before_action { authorized_search?(@twitter_user) && !blocked_search?(@twitter_user) }

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
    uid, screen_name = @twitter_user.uid.to_i, @twitter_user.screen_name
    redirect_path = sanitized_redirect_path(params[:redirect_path].presence || timeline_path(@twitter_user))

    if TwitterUser.exists?(uid: uid)
      redirect_to redirect_path
    else
      unless too_many_searches?(@twitter_user) || too_many_requests?(@twitter_user) || performed?
        save_twitter_user_to_cache(uid, screen_name, @twitter_user.raw_attrs_text)
        jid = enqueue_create_twitter_user_job_if_needed(uid, user_id: current_user_id, screen_name: screen_name)
        redirect_to waiting_search_path(uid: uid, redirect_path: redirect_path, jid: jid)

        UpdateSearchHistoriesWorker.perform_async(fingerprint, current_user_id, @twitter_user.uid)
      end
    end
  end
end
