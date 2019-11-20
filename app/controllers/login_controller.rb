class LoginController < ApplicationController

  before_action :reject_crawler, only: %i(sign_in sign_out)
  before_action :push_referer, only: %i(sign_in sign_out)
  before_action :create_search_log, only: %i(sign_in sign_out)

  def goodbye
    redirect_to root_path, notice: t('.signed_out') unless user_signed_in?
  end

  def sign_in
    session[:sign_in_from] = request.url
    if !session[:sign_in_referer] && !session[:sign_in_via]
      session[:sign_in_referer] = request.referer
      session[:sign_in_via] = params['via']
    end

    if params['ab_test']
      session[:sign_in_ab_test] = params['ab_test']
    end

    force_login = params[:force_login] && params[:force_login] == 'true'

    session[:sign_in_follow] = 'true' == params[:follow] ? 'true' : 'false'
    session[:sign_in_tweet] = 'true' == params[:tweet] ? 'true' : 'false'
    session[:redirect_path] = params[:redirect_path].presence || root_path
    redirect_to "/users/auth/twitter?force_login=#{force_login}"
  end

  # This implementation is for logging.
  # GET /goodbye -> DELETE /sign_out -> this action
  def sign_out
    redirect_to destroy_user_session_path
  end
end
