class StatusesController < ApplicationController
  include Concerns::Showable

  def show
    statuses = @twitter_user.statuses.limit(20)
    @statuses = statuses.select(&:user)

    if statuses.size != @statuses.size
      logger.warn "Status doesn't have user. #{@twitter_user.inspect}"
    end
  end
end
