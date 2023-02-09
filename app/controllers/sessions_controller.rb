class SessionsController < ApplicationController

  skip_before_action :validate_api_authorization!
  skip_before_action :validate_account_suspension!
  skip_before_action :validate_dm_permission!
  skip_before_action :current_user_not_blocker?

  before_action :reject_crawler
  before_action :check_counter

  def new
    session[:sign_in_via] = params[:via]
    session[:sign_in_follow] = 'true' == params[:follow] ? 'true' : 'false'
    session[:redirect_path] = params[:redirect_path]
  end

  private

  def check_counter
    counter = LoginCounter.new(current_visit.visitor_token)
    if counter.value > 0
      @consecutive_access = true
      Airbag.info 'Consecutive access found', count: counter.value, visitor_token: current_visit.visitor_token
    end
    counter.increment
  rescue => e
  end
end
