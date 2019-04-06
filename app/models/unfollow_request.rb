# == Schema Information
#
# Table name: unfollow_requests
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
#  index_unfollow_requests_on_created_at  (created_at)
#  index_unfollow_requests_on_user_id     (user_id)
#

class UnfollowRequest < ApplicationRecord
  include Concerns::Request::FollowAndUnfollow
  include Concerns::Request::Runnable

  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer

  def perform!
    raise AlreadyFinished if finished?
    raise Unauthorized if user.unauthorized?
    raise CanNotUnfollowYourself if user.uid == uid
    raise NotFound unless user_found?
    raise NotFollowing unless friendship?

    raise GlobalTooManyUnfollows unless global_can_perform?
    raise UserTooManyUnfollows unless user_can_perform?

    begin
      client.unfollow(uid)
    rescue Twitter::Error::Unauthorized => e
      raise Unauthorized.new(e.message)
    rescue Twitter::Error::Forbidden => e
      if e.message.start_with?('To protect our users from spam and other malicious activity, this account is temporarily locked.')
        raise TemporarilyLocked
      else
        raise Forbidden.new(e.message)
      end
    end
  end

  TOO_MANY_FOLLOWS_INTERVAL = 1.hour
  NORMAL_INTERVAL = 1.second

  def perform_interval
    if global_can_perform? && user_can_perform?
      NORMAL_INTERVAL
    else
      TOO_MANY_FOLLOWS_INTERVAL
    end
  end

  def global_can_perform?
    time = CreateUnfollowLog.global_last_too_many_follows_time
    time.nil? || time + TOO_MANY_FOLLOWS_INTERVAL < Time.zone.now
  end

  def user_can_perform?
    time = CreateUnfollowLog.user_last_too_many_follows_time(user_id)
    time.nil? || time + TOO_MANY_FOLLOWS_INTERVAL < Time.zone.now
  end

  def user_found?
    client.user?(uid)
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

  class GlobalTooManyUnfollows < DeadErrorTellsNoTales
  end

  class UserTooManyUnfollows < DeadErrorTellsNoTales
  end

  class CanNotUnfollowYourself < DeadErrorTellsNoTales
  end

  class NotFound < DeadErrorTellsNoTales
  end

  class NotFollowing < DeadErrorTellsNoTales
  end
end
