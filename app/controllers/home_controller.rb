class HomeController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :require_login!, only: :start, unless: :from_crawler?

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
    enqueue_update_authorized

    if params[:back_from_twitter] == 'true'
      flash.now[:notice] = t('before_sign_in.back_from_twitter_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/back_from_twitter"))
    end

    if flash.empty? && user_signed_in?
      if TwitterUser.exists?(uid: current_user.uid)
        url = timeline_path(screen_name: current_user.screen_name, via: build_via('auto_redirect'))
      else
        url = start_path(via: build_via('auto_redirect'))
      end

      url = append_query_params(url, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
      url = append_query_params(url, share_dialog: params[:share_dialog]) if params[:share_dialog]
      redirect_to url
    end
  end

  def start
    if user_signed_in?
      if params[:save_context] == 'update' && TwitterUser.exists?(uid: current_user.uid)
        url = timeline_path(screen_name: current_user.screen_name, via: build_via('auto_redirect_from_start'))
        url = append_query_params(url, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
        url = append_query_params(url, share_dialog: params[:share_dialog]) if params[:share_dialog]
        redirect_to url
      else
        @user = build_twitter_user_by_uid(current_user.uid) # It's possible to be redirected
        @screen_name = @user.screen_name
      end
    else
      @user = nil
      @screen_name = 'Visitor'
    end
  end
end
