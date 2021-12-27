class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: [:show]

  def index
  end

  def show
    @delete_tweets_request = current_user.delete_tweets_requests.order(created_at: :desc).first
  end

  def faq
  end
end
