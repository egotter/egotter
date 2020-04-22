class BlockedController < ApplicationController
  include Concerns::CheckExistenceConcern

  prepend_before_action do
    @resource_name = 'blocked'
  end

  prepend_before_action :require_login!

  private

  def delete_resource_async
  end

  def resource_found?
    !blocked_user?(params[:screen_name]) && params['redirect'] != 'false'
  end

  def latest_resource_path(screen_name)
    @latest_resource_path = latest_blocked_path(screen_name: screen_name, via: current_via('request_to_update'))
  end

  def set_canonical_url
    @canonical_url =
        if @user
          blocked_url(@user)
        else
          blocked_url(screen_name: @screen_name)
        end
  end
end
