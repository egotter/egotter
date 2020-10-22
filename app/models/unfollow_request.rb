# == Schema Information
#
# Table name: unfollow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :bigint(8)        not null
#  requested_by  :string(191)      default(""), not null
#  finished_at   :datetime
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_unfollow_requests_on_created_at  (created_at)
#  index_unfollow_requests_on_user_id     (user_id)
#

class UnfollowRequest < ApplicationRecord
  include FollowRequestRunnable

  has_many :logs, primary_key: :id, foreign_key: :request_id, class_name: 'CreateUnfollowLog'

  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer

  before_validation do
    if self.requested_by
      self.requested_by = self.requested_by.truncate(100)
    end

    if self.error_message
      self.error_message = self.error_message.truncate(100)
    end
  end

  class << self
    # The finished_at is null and the error_class is empty.
    def finished(user_id:, created_at:)
      where(user_id: user_id).
          where('created_at > ?', created_at).
          where.not(finished_at: nil).
          where(error_class: '')
    end

    # The finished_at is NOT null and there are no logs.
    def unprocessed(user_id:, created_at:)
      includes(:logs).
          where(user_id: user_id).
          where('created_at > ?', created_at).
          where(finished_at: nil).
          where(error_class: '').
          select { |req| req.logs.empty? }
    end

    def temporarily_unfollowing(user_id:, created_at:)
      (finished(user_id: user_id, created_at: created_at) + unprocessed(user_id: user_id, created_at: created_at)).sort_by(&:created_at)
    end
  end

  def perform!
    error_check! unless @error_check
    client.unfollow(uid)

  rescue Error, RetryableError => e
    raise
  rescue Twitter::Error::Unauthorized => e
    raise Unauthorized.new(e.message)
  rescue Twitter::Error::Forbidden => e
    if TwitterApiStatus.temporarily_locked?(e)
      raise TemporarilyLocked
    else
      raise Forbidden.new(e.message)
    end
  end

  def error_check!
    raise TooManyRetries if logs.size >= 5
    raise AlreadyFinished if finished?
    raise Unauthorized if unauthorized?
    raise CanNotUnfollowYourself if user.uid == uid
    raise NotFound if not_found?
    raise NotFollowing unless friendship?

    @error_check = true
  end

  def unauthorized?
    !user.authorized? || !client.verify_credentials
  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e)
      true
    else
      raise
    end
  end

  def not_found?
    !client.user?(uid)
  rescue => e
    if TwitterApiStatus.temporarily_locked?(e)
      raise TemporarilyLocked
    elsif TwitterApiStatus.suspended?(e)
      raise Suspended
    else
      raise
    end
  end

  def friendship?
    client.friendship?(user.uid, uid)
  end

  def client
    @client ||= user.api_client.twitter
  end

  class Error < StandardError
  end

  class RetryableError < StandardError
  end

  # Don't retry
  class TooManyRetries < Error
  end

  class AlreadyFinished < Error
  end

  # Don't retry
  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class Suspended < Error
  end

  class TemporarilyLocked < Error
  end

  class TooManyUnfollows < RetryableError
  end

  # Don't retry
  class CanNotUnfollowYourself < Error
  end

  # Don't retry
  class NotFound < Error
  end

  # Don't retry
  class NotFollowing < Error
  end
end
