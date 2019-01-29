require 'active_support/concern'

module Concerns::Request::FollowAndUnfollow
  extend ActiveSupport::Concern

  included do
    scope :without_error, -> {where("error_message is null or error_message = '' or error_message like 'You are unable to follow more people at this time.%'")}

    scope :unprocessed, -> user_id {
      where(user_id: user_id, finished_at: nil).
          without_error
    }

    scope :finished, -> user_id {
      where(user_id: user_id).
          where.not(finished_at: nil)
    }
  end

  def finished!
    update!(finished_at: Time.zone.now) if finished_at.nil?
  end
end