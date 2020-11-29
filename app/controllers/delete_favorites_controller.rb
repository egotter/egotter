class DeleteFavoritesController < ApplicationController
  before_action :require_login!, only: :show

  before_action only: :show do
    unless current_user.authorized?
      redirect_to root_path(via: current_via), alert: unauthorized_message(current_user.screen_name)
    end
  end

  before_action do
    unless current_user.admin?
      redirect_to root_path(via: current_via), alert: t('before_sign_in.coming_soon')
    end
  end

  # TODO Rename to #index
  def new
  end

  def show
    @request = current_user.delete_favorites_requests.order(created_at: :desc).first
    @processing = @request && @request.processing?
  end
end
