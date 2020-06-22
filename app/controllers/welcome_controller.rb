class WelcomeController < ApplicationController
  def new
    redirect_to sign_in_path
  end
end
