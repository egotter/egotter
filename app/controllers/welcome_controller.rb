class WelcomeController < ApplicationController

  before_action :push_referer
  before_action :create_search_log

  def new
    redirect_to sign_in_path
  end
end
