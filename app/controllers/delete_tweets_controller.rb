class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: [:show]

  def index
  end

  def show
    if (request = current_user.delete_tweets_requests.order(created_at: :desc).first)
      @processing = request.processing?
    end
    @max_count = DeleteTweetsRequest::DESTROY_LIMIT
  end

  def faq
  end
end
