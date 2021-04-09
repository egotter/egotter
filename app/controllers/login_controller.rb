class LoginController < ApplicationController

  skip_before_action :current_user_authorized?
  skip_before_action :current_user_has_dm_permission?
  skip_before_action :current_user_not_blocker?

  before_action :require_login!, only: %i(after_sign_in after_sign_up)
  before_action :reject_crawler, except: :goodbye

  def goodbye
    unless user_signed_in?
      redirect_to root_path(via: current_via('already_signed_out')), notice: t('.signed_out')
    end
  end

  def sign_in
    if params['ab_test']
      session[:sign_in_ab_test] = params['ab_test']
    end

    session[:sign_in_via] = params[:via]
    session[:sign_in_follow] = 'true' == params[:follow] ? 'true' : 'false'
    session[:redirect_path] = params[:redirect_path]

    redirect_to "/users/auth/twitter?force_login=#{params[:force_login] == 'true'}"
  end

  # This action is created for conversion tracking.
  def after_sign_up
    @redirect_path = params[:redirect_path] || root_path(via: current_via('unknown'))
    set_bypassed_notice_message('after_sign_up')
  end

  # This action is created for conversion tracking.
  def after_sign_in
    @redirect_path = params[:redirect_path] || root_path(via: current_via('unknown'))
    set_bypassed_notice_message('after_sign_in')
  end

  # This implementation is for logging.
  # GET /goodbye -> DELETE /sign_out -> this action
  def sign_out
    redirect_to destroy_user_session_path
  end
end
