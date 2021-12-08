class SearchesController < ApplicationController
  include JobQueueingConcern
  include SanitizationConcern
  include SearchHistoriesConcern
  include PathsHelper

  before_action :reject_crawler
  before_action :valid_screen_name?
  before_action :not_found_screen_name?
  before_action :forbidden_screen_name?
  before_action do
    request = SearchRequest.request_for(current_user&.id, params[:screen_name])

    if request
      if request.ok?
        @twitter_user = TwitterUser.new(uid: request.uid, screen_name: request.screen_name)
      else
        session[:screen_name] = request.screen_name
        redirect_to redirect_path_for_search_request(request)
      end
    else
      request = SearchRequest.create!(
          user_id: current_user&.id,
          uid: nil,
          screen_name: params[:screen_name],
          properties: {remaining_count: @search_count_limitation.remaining_count, search_histories: current_search_histories.map(&:uid)}
      )
      CreateSearchRequestWorker.perform_async(request.id)

      @screen_name = request.screen_name
      @user = TwitterDB::User.find_by(screen_name: request.screen_name)
      self.sidebar_disabled = true
      render template: 'searches/create'
    end
  rescue => e
    logger.warn "Debug SearchRequest #{e.inspect}"
  end
  # TODO Remove start
  # before_action { @self_search = current_user_search_for_yourself?(params[:screen_name]) }
  # before_action { !@self_search && not_found_twitter_user?(params[:screen_name]) }
  # before_action { !@self_search && forbidden_twitter_user?(params[:screen_name]) }
  # before_action { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
  # before_action { private_mode_specified?(@twitter_user) }
  # before_action { search_limitation_soft_limited?(@twitter_user) }
  # before_action { !@self_search && !protected_search?(@twitter_user) }
  # before_action { !@self_search && !blocked_search?(@twitter_user) }
  # before_action { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) }
  # before_action { too_many_friends?(@twitter_user) }
  # TODO Remove end
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
