class WelcomeController < ApplicationController

  before_action :push_referer
  before_action :create_search_log

  def new
    session[:sign_in_referer] = request.referer
    session[:sign_in_via] = params['via']

    if params['ab_test']
      session[:sign_in_ab_test] = params['ab_test']
    end

    @redirect_path = params[:redirect_path].presence || root_path
  end
end
