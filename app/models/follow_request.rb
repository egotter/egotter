# == Schema Information
#
# Table name: follow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :bigint(8)        not null
#  requested_by  :string(191)      default(""), not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  finished_at   :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_follow_requests_on_created_at  (created_at)
#  index_follow_requests_on_user_id     (user_id)
#

class FollowRequest < ApplicationRecord
  include FollowRequestRunnable

  has_many :logs, primary_key: :id, foreign_key: :request_id, class_name: 'CreateFollowLog'

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

    def temporarily_following(user_id:, created_at:)
      (finished(user_id: user_id, created_at: created_at) + unprocessed(user_id: user_id, created_at: created_at)).sort_by(&:created_at)
    end

    def requests_for_egotter
      where(finished_at: nil).
          where(uid: User::EGOTTER_UID).
          where(error_class: '')
    end
  end

  def perform!
    error_check! unless @error_check
    client.follow!(uid)

  rescue Error, RetryableError => e
    raise
  rescue Twitter::Error::Unauthorized => e
    raise Unauthorized.new(e.message)
  rescue Twitter::Error::Forbidden => e
    case
    when TwitterApiStatus.temporarily_locked?(e)
      raise TemporarilyLocked
    when TwitterApiStatus.your_account_suspended?(e)
      raise Suspended
    when TwitterApiStatus.blocked_from_following?(e)
      raise Blocked
    when TwitterApiStatus.unable_to_follow?(e)
      GlobalFollowLimitation.new.limit_start
      raise TooManyFollows
    else
      raise Forbidden.new(e.message)
    end
  rescue Twitter::Error::ServiceUnavailable => e
    raise ServiceUnavailable
  end

  def error_check!
    raise TooManyRetries if logs.size >= 5
    raise AlreadyFinished if finished?
    raise Unauthorized if unauthorized?
    raise CanNotFollowYourself if user.uid == uid
    raise NotFound if not_found?
    raise AlreadyRequestedToFollow if friendship_outgoing?
    raise AlreadyFollowing if friendship?

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

  # Returns a collection of numeric IDs for every protected user for whom the authenticating user has a pending follow request.
  # TODO Cache this value.
  def friendship_outgoing?
    client.friendships_outgoing.attrs[:ids].include?(uid)
  rescue => e
    logger.warn "#{__method__} Always return false #{e.class} #{e.message} #{self.slice(:id, :user_id, :uid)}"
    false
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

  # Don't retry
  class Blocked < Error
  end

  class Forbidden < Error
  end

  # Don't retry
  class Suspended < Error
  end

  # Don't retry
  class TemporarilyLocked < Error
  end

  class TooManyFollows < RetryableError
  end

  # Don't retry
  class CanNotFollowYourself < Error
  end

  # Don't retry
  class NotFound < Error
  end

  # Don't retry
  class AlreadyFollowing < Error
  end

  # Don't retry
  class AlreadyRequestedToFollow < Error
  end

  class ServiceUnavailable < Error
  end
end
