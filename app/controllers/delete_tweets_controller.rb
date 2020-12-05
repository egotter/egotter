class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: [:show]

  # TODO Rename to #index
  def new
  end

  def show
    if (request = current_user.delete_tweets_requests.order(created_at: :desc).first)
      @processing = request.processing?
      @request = DeleteTweetsRequestDecorator.new(request)
    end
  end
end
