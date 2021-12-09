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
      if user_signed_in?
        request_creating_twitter_user(@twitter_user.uid)
        redirect_to waiting_path(screen_name: @twitter_user.screen_name, redirect_path: redirect_path, via: current_via)
      else
        session[:screen_name] = @twitter_user.screen_name
        redirect_to error_pages_twitter_user_not_persisted_path(via: current_via)
      end
    end
  end
end
