require 'active_support/concern'

module Concerns::CheckExistenceConcern
  extend ActiveSupport::Concern

  included do
    before_action :valid_screen_name?

    before_action only: :latest do
      request_context_client.user(params[:screen_name])
    rescue => e
      notify_airbrake(e)
    else
      delete_resource_async
    end

    before_action unless: :twitter_crawler? do
      # When redirected from another controller (e.g. blocked_controller),
      # there may be an unnecessary message.
      flash[:notice] = nil

      if resource_found?
        flash[:notice] = t("#{@resource_name}.show.come_back", user: params[:screen_name])
        redirect_to timeline_path(screen_name: params[:screen_name], via: current_via("#{@resource_name}_redirect"))
      end
    end

    before_action do
      # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
      self.sidebar_disabled = true
    end
    before_action :create_search_log
    before_action :set_user
    before_action :set_screen_name
    before_action :set_canonical_url
  end

  def show
    @alert = t(".displayed_data_is_html", user: @screen_name, url: url_on_alert(@screen_name))
    render template: (@user ? 'not_found/show' : 'not_found/not_persisted')
  end

  def latest
    show
  end


  private

  def set_user
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user
  end

  def set_screen_name
    @screen_name = @user&.screen_name || params[:screen_name]
  end


  def url_on_alert(screen_name)
    url = latest_resource_path(screen_name)
    url = sign_in_path(via: current_via('request_to_update'), redirect_path: url) unless user_signed_in?
    url
  end
end
