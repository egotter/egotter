class DeleteFavoritesController < ApplicationController
  before_action :require_login!, only: :show

  # TODO Rename to #index
  def new
  end

  def show
    @delete_favorites_request = current_user.delete_favorites_requests.order(created_at: :desc).first
  end

  def faq
  end
end
