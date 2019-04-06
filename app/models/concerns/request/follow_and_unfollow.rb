require 'active_support/concern'

module Concerns::Request::FollowAndUnfollow
  extend ActiveSupport::Concern

  included do
    scope :without_error, -> do
      sql = <<~SQL
        error_message is null
        or error_message = ''
        or error_message like 'You are unable to follow more people at this time.%'
        or error_message like 'Follow or unfollow limit exceeded%'
      SQL
      where(sql)
    end

    # Don't include 'Follow or unfollow limit exceeded' as using to check perform_limit_reset_at
    # TODO To change the query for UnfollowRequest
    scope :with_limit_error, -> {where("error_message like 'You are unable to follow more people at this time.%'")}

    scope :unprocessed, -> user_id {
      where(user_id: user_id, finished_at: nil).
          where.not(uid: User::EGOTTER_UID).
          where(created_at: 1.day.ago..Time.zone.now).
          without_error
    }
  end

  class_methods do
  end
end
