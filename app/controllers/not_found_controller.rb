class NotFoundController < ApplicationController
  include Concerns::CheckExistenceConcern

  prepend_before_action do
    @resource_name = 'not_found'
  end

  private

  def delete_resource_async
    DeleteNotFoundUserWorker.new.perform(params[:screen_name])
  end

  def resource_found?
    !NotFoundUser.exists?(screen_name: params[:screen_name]) &&
        !not_found_user?(params[:screen_name]) &&
        params['redirect'] != 'false'
  end

  def latest_resource_path(screen_name)
    @latest_resource_path = latest_not_found_path(screen_name: screen_name, via: current_via('request_to_update'))
  end

  def set_canonical_url
    @canonical_url =
        if @user
          not_found_url(@user)
        else
          not_found_url(screen_name: @screen_name)
        end
  end
end
