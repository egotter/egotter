class NotFoundController < ApplicationController
  before_action :valid_screen_name?

  before_action only: :latest do
    request_context_client.user(params[:screen_name])
  rescue => e
    logger.info "#{controller_name}##{action_name} #{e.inspect}"
  else
    DeleteNotFoundUserWorker.new.perform(params[:screen_name])
  end

  before_action unless: :twitter_crawler? do
    if !NotFoundUser.exists?(screen_name: params[:screen_name]) && !not_found_user?(params[:screen_name])
      redirect_to timeline_path(screen_name: params[:screen_name], via: build_via('not_found_redirect')), notice: t('not_found.show.come_back', user: params[:screen_name])
    end
  end

  before_action :create_search_log

  def show
    # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
    self.sidebar_disabled = true
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user

    flash.now[:alert] = flash_message(@use&.screen_name || params[:screen_name])
    @user ? render('show') : render('not_persisted')
  end

  # Separated endpoint
  def latest
    show
  end

  private

  def flash_message(screen_name)
    url = latest_not_found_path(screen_name: screen_name, via: build_via('request_to_update'))
    url = sign_in_path(via: build_via('request_to_update'), redirect_path: url) unless user_signed_in?
    t("not_found.#{action_name}.displayed_data_is_html", user: screen_name, url: url)
  end
end
