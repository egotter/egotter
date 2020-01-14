class StatusesController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    statuses = @twitter_user.status_tweets.take(20)
    @statuses = statuses.select(&:user)

    if statuses.size != @statuses.size
      logger.warn "Status doesn't have user. Continue to rendering #{@twitter_user.inspect}"
    end
  end
end
