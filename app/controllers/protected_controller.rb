class ProtectedController < ApplicationController
  include Concerns::CheckExistenceConcern

  prepend_before_action do
    @resource_name = 'protected'
  end

  private

  def delete_resource_async
  end

  def resource_found?
    !protected_user?(params[:screen_name]) && params['redirect'] != 'false'
  end

  def latest_resource_path(screen_name)
    @latest_resource_path = latest_protected_path(screen_name: screen_name, via: current_via('request_to_update'))
  end

  def set_canonical_url
    @canonical_url =
        if @user
          protected_url(@user)
        else
          protected_url(screen_name: @screen_name)
        end
  end
end
