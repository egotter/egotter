class LoginController < ApplicationController
  include Logging

  before_action :create_search_log, only: %i(welcome sign_in sign_out)

  # GET /welcome
  def welcome
    redirect_to '/', notice: t('dictionary.signed_in') if user_signed_in?
    session[:sign_in_from] = request.referer if request.referer.present?
  end

  # GET /sign_in
  def sign_in
    redirect_to '/users/auth/twitter'
  end

  # GET /sign_out
  def sign_out
    redirect_to destroy_user_session_path
  end
end
