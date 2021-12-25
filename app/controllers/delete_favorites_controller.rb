class DeleteFavoritesController < ApplicationController
  before_action :require_login!, only: :show

  # TODO Rename to #index
  def new
  end

  def show
    if (request = current_user.delete_favorites_requests.order(created_at: :desc).first)
      @processing = request.processing?
    end
    @max_count = DeleteFavoritesRequest::DESTROY_LIMIT
  end

  def faq
  end
end
