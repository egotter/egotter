class StatusesController < ApplicationController
  include Concerns::Showable

  def show
    @statuses = @twitter_user.statuses.limit(20)
  end
end
