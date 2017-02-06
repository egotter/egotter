class LoginController < ApplicationController
  include SearchesHelper
  include Concerns::Logging

  before_action :reject_crawler, only: %i(sign_in sign_out)
  before_action :push_referer, only: %i(welcome sign_in sign_out)
  before_action :create_search_log, only: %i(sign_out)
  before_action only: %i(sign_in) do
    create_search_log(ab_test: session[:sign_in_ab_test] ? session[:sign_in_ab_test] : 'direct')
  end
  before_action only: %i(welcome) do
    create_search_log(ab_test: 'welcome')
  end

  # GET /welcome
  def welcome
    redirect_to root_path, notice: t('dictionary.signed_in') if user_signed_in?
    session[:sign_in_referer] = request.referer
    session[:sign_in_via] = params['via']
    session[:sign_in_ab_test] = 'welcome'
    @redirect_path = params[:redirect_path].presence || root_path
  end

  # GET /sign_in
  def sign_in
    session[:sign_in_from] = request.url
    if !session[:sign_in_referer] && !session[:sign_in_via] && !session[:sign_in_ab_test]
      session[:sign_in_referer] = request.referer
      session[:sign_in_via] = params['via']
      session[:sign_in_ab_test] = 'direct'
    end
    session[:sign_in_follow] = 'true' == params[:follow] ? 'true' : 'false'
    session[:redirect_path] = params[:redirect_path].presence || root_path
    redirect_to '/users/auth/twitter'
  end

  # GET /sign_out
  def sign_out
    redirect_to destroy_user_session_path
  end
end
