# == Schema Information
#
# Table name: follow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :bigint(8)        not null
#  finished_at   :datetime
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_follow_requests_on_created_at  (created_at)
#  index_follow_requests_on_user_id     (user_id)
#

class FollowRequest < ApplicationRecord
  include Concerns::Request::FollowAndUnfollow
  include Concerns::Request::Runnable

  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer

  def perform!
    raise AlreadyFinished if finished?
    raise Unauthorized unless user.authorized?
    raise CanNotFollowYourself if user.uid == uid
    raise NotFound unless user_found?
    raise AlreadyRequestedToFollow if friendship_outgoing?
    raise AlreadyFollowing if friendship?

    raise GlobalRateLimited if global_rate_limited?
    raise UserRateLimited if user_rate_limited?

    begin
      client.follow!(uid)
    rescue Twitter::Error::Unauthorized => e
      raise Unauthorized.new(e.message)
    rescue Twitter::Error::Forbidden => e
      if e.message.start_with?('To protect our users from spam and other malicious activity, this account is temporarily locked.')
        raise TemporarilyLocked
      elsif e.message.start_with?('You are unable to follow more people at this time.')
        raise TooManyFollows
      else
        raise Forbidden.new(e.message)
      end
    end
  end

  TOO_MANY_FOLLOWS_INTERVAL = 1.hour
  NORMAL_INTERVAL = 1.second

  def perform_interval
    if !global_rate_limited? && !user_rate_limited?
      NORMAL_INTERVAL
    else
      TOO_MANY_FOLLOWS_INTERVAL
    end
  end

  def global_rate_limited?
    time = CreateFollowLog.global_last_too_many_follows_time
    time && Time.zone.now < time + TOO_MANY_FOLLOWS_INTERVAL
  end

  def user_rate_limited?
    time = CreateFollowLog.user_last_too_many_follows_time(user_id)
    time && Time.zone.now < time + TOO_MANY_FOLLOWS_INTERVAL
  end

  def user_found?
    client.user?(uid)
  end

  def friendship_outgoing?
    client.friendships_outgoing.attrs[:ids].include?(uid)
  rescue => e
    logger.warn "#{__method__} #{e.class} #{e.message} #{self.inspect}"
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

  class DeadErrorTellsNoTales < Error
    def initialize(*args)
      super('')
    end
  end

  class AlreadyFinished < DeadErrorTellsNoTales
  end

  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class TemporarilyLocked < DeadErrorTellsNoTales
  end

  class GlobalRateLimited < DeadErrorTellsNoTales
  end

  class UserRateLimited < DeadErrorTellsNoTales
  end

  class TooManyFollows < DeadErrorTellsNoTales
  end

  class CanNotFollowYourself < DeadErrorTellsNoTales
  end

  class NotFound < DeadErrorTellsNoTales
  end

  class AlreadyFollowing < DeadErrorTellsNoTales
  end

  class AlreadyRequestedToFollow < DeadErrorTellsNoTales
  end
end
