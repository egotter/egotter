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
    CreateCacheWorker.perform_async(user_id: current_user.id, enqueued_at: Time.zone.now) if user_signed_in?

    if user_signed_in? && TwitterUser.exists?(uid: current_user.uid)
      redirect_path = timeline_path(screen_name: current_user.screen_name)
      redirect_path = append_query_params(redirect_path, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
      redirect_path = append_query_params(redirect_path, share_dialog: params[:share_dialog]) if params[:share_dialog]
      redirect_to redirect_path
    end
  end
end
