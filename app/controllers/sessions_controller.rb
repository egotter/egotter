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
    if current_visit
      id = current_visit.visitor_token
      if LoginCounter.value(id) > 0
        @consecutive_access = true
        Airbag.info 'Consecutive access found', count: LoginCounter.value(id), visitor_token: id
      end
      LoginCounter.increment(id)
    end
  rescue => e
    Airbag.exception e
  end
end
