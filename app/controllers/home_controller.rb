class HomeController < ApplicationController
  before_action do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def new
    if user_signed_in? && TwitterUser.exists?(uid: current_user.uid)
      redirect_to timeline_path screen_name: current_user.screen_name
    end
  end
end
