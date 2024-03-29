class LoginController < ApplicationController

  skip_before_action :validate_api_authorization!
  skip_before_action :validate_account_suspension!
  skip_before_action :validate_dm_permission!
  skip_before_action :current_user_not_blocker?

  before_action :require_login!, only: %i(after_sign_in after_sign_up sign_out)
  before_action :reject_crawler, except: :goodbye

  def goodbye
    unless user_signed_in?
      redirect_to root_path(via: current_via('already_signed_out')), notice: t('.signed_out')
    end
  end

  def sign_in
    redirect_to login_path
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
    if params[:stop_all_reports] == 'true'
      StopAllReportsWorker.perform_async(current_user.id)
    end
    redirect_to destroy_user_session_path
  end
end
