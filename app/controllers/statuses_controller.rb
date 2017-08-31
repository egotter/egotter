class StatusesController < ApplicationController
  include Concerns::Showable

  def show
    @statuses = @twitter_user.statuses.limit(20)

    # TODO Experimental
    words = BlacklistWord.all.pluck(:text)
    hacked = @statuses.select { |tweet| words.any? { |w| tweet.text.include?(w) } }
    if hacked.any?
      logger.warn "hacked #{current_user_id} #{@twitter_user.uid} #{hacked.size} #{hacked.first.text}"
    end
  end
end
