# == Schema Information
#
# Table name: create_prompt_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_create_prompt_report_requests_on_created_at  (created_at)
#  index_create_prompt_report_requests_on_user_id     (user_id)
#

class CreatePromptReportRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user

  validates :user_id, presence: true

  def perform!
    raise Unauthorized unless user.authorized?
    raise ReportDisabled unless user.can_send_dm?
    raise Inactive unless user.active?(14)
    raise RecordNotFound unless TwitterUser.exists?(uid: user.uid)

    t_user = fetch_user
    raise Suspended if t_user[:suspended]
    raise TooManyFriends if TwitterUser.too_many_friends?(t_user, login_user: user)

    twitter_user = self.twitter_user
    raise TooManyFriends if twitter_user.too_many_friends?(login_user: user)
    raise MaybeImportBatchFailed if twitter_user.no_need_to_import_friendships?

    friend_uids, follower_uids = friend_uids_and_follower_uids
    raise Unauthorized if friend_uids.nil? && follower_uids.nil?

    latest = TwitterUser.new.tap do |user|
      user.friend_uids = friend_uids
      user.follower_uids = follower_uids
    end

    new_unfollower_uids = UnfriendsBuilder::Util.unfollowers(twitter_user, latest)
    raise UnfollowersNotChanged if new_unfollower_uids.none?

    changes = {followers_count: [twitter_user.follower_uids.size, latest.follower_uids.size]}

    last_report = PromptReport.latest(user.id)
    raise MessageNotChanged if last_report && changes == last_report.last_changes

    send_report!(changes)
  end

  def send_report!(changes)
    PromptReport.you_are_removed(user.id, changes_json: changes.to_json).deliver
  rescue => e
    logger.warn "#{e.class} #{e.message} #{self.inspect} #{changes.inspect}"
    logger.info e.backtrace.join("\n")

    raise DirectMessageNotSent.new(e.message.truncate(100))
  end

  def twitter_user
    latest_user = TwitterUser.where('created_at < ?', user.last_access_at).latest_by(uid: user.uid) if user.last_access_at
    latest_user = TwitterUser.latest_by(uid: user.uid) unless latest_user
    latest_user
  end

  private

  def fetch_user
    client.user(user.uid)
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise
  end

  def friend_uids_and_follower_uids
    client.friend_ids_and_follower_ids(user.uid)
  rescue Twitter::Error::Unauthorized => e
    raise unless e.message != 'Invalid or expired token.'
    [nil, nil]
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise
  end

  def client
    @client ||= user.api_client
  end

  class Error < StandardError
    def initialize(*args)
      super('')
    end
  end

  class Unauthorized < Error
  end

  class ReportDisabled < Error
  end

  class Inactive < Error
  end

  class RecordNotFound < Error
  end

  class Suspended < Error
  end

  class TooManyFriends < Error
  end

  class MaybeImportBatchFailed < Error
  end

  class UnfollowersNotChanged < Error
  end

  class MessageNotChanged < Error
  end

  class DirectMessageNotSent < Error
  end
end
