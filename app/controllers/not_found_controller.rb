class NotFoundController < ApplicationController

  before_action :valid_screen_name?

  before_action do
    if params[:force_update] == 'true'
      begin
        request_context_client.user(params[:screen_name])
      rescue => e
        logger.info "#{self.class} force_update #{e.inspect}"
      else
        DeleteNotFoundUserWorker.new.perform(params[:screen_name])
      end
    end
  end

  before_action do
    if NotFoundUser.exists?(screen_name: params[:screen_name]) || not_found_user?(params[:screen_name])
      true
    else
      via = params[:force_update] == 'true' ? 'not_found_force_update' : 'not_found_redirect'
      redirect_to timeline_path(screen_name: params[:screen_name], via: build_via(via))
      false
    end
  end

  before_action :create_search_log

  def show
    screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: screen_name)
    @user = TwitterUser.latest_by(screen_name: screen_name) unless @user

    # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
    self.sidebar_disabled = true

    flash.now[:alert] = not_found_with_request_message(screen_name, not_found_path(screen_name: screen_name, via: build_via('force_update_message'), force_update: 'true'))
    @user ? render : (render 'not_persisted')
  end
end
