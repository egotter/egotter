# == Schema Information
#
# Table name: create_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  session_id      :string(191)
#  user_id         :integer          not null
#  uid             :bigint(8)        not null
#  twitter_user_id :integer
#  status_message  :string(191)
#  requested_by    :string(191)      default(""), not null
#  started_at      :datetime
#  finished_at     :datetime
#  failed_at       :datetime
#  ahoy_visit_id   :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_create_twitter_user_requests_on_created_at       (created_at)
#  index_create_twitter_user_requests_on_twitter_user_id  (twitter_user_id)
#  index_create_twitter_user_requests_on_user_id          (user_id)
#

class CreateTwitterUserRequest < ApplicationRecord
  include RequestRunnable
  belongs_to :user, optional: true
  belongs_to :twitter_user, optional: true

  validates :user_id, presence: true
  validates :uid, presence: true

  class << self
    def too_short_request_interval?(uid)
      where(created_at: 3.minutes.ago..Time.zone.now).where(uid: uid).exists?
    end
  end

  # context:
  #   :reporting
  def perform(context = nil)
    if started_at || finished_at || failed_at
      return
    end

    update(started_at: Time.zone.now)
    validate_request!
    validate_creation_interval!

    snapshot, relations = build_snapshot(context)
    validate_creation_interval!

    FriendsCountPoint.create(uid: snapshot.uid, value: snapshot.friends_count)
    FollowersCountPoint.create(uid: snapshot.uid, value: snapshot.followers_count)

    validate_twitter_user!(snapshot)

    if user && SearchLimitation.warn_limit?(snapshot)
      TooManyFriendsSearchedFlag.on(user.id)
    end

    assemble_twitter_user(snapshot, relations)
    validate_creation_interval!
    twitter_user = save_twitter_user(snapshot)

    enqueue_creation_jobs(snapshot.friend_uids, snapshot.follower_uids, twitter_user.user_id, context)
    enqueue_new_friends_creation_jobs(twitter_user.id, context)
    update(finished_at: Time.zone.now)

    twitter_user
  rescue => e
    update(failed_at: Time.zone.now, status_message: e.class)
    raise
  end

  def enqueue_creation_jobs(friend_uids, follower_uids, user_id, context, slice: 50)
    if context == :reporting
      Airbag.info '[REPORTING] CreateTwitterDBUserWorker is not enqueued', request_id: id, uid: uid, context: context
      CreateTwitterDBUsersForMissingUidsWorker.push_bulk(friend_uids + follower_uids, user_id, enqueued_by: "#{self.class.name}-#{context}")
    else
      CreateTwitterDBUserWorker.push_bulk(friend_uids.take(slice) + follower_uids.take(slice), user_id: user_id, enqueued_by: self.class.name)
      CreateTwitterDBUsersForMissingUidsWorker.push_bulk(
          (friend_uids.slice(slice..-1) || []) + (follower_uids.slice(slice..-1) || []), user_id, enqueued_by: self.class.name)
    end
  end

  def enqueue_new_friends_creation_jobs(twitter_user_id, context)
    if context == :reporting
      Airbag.info '[REPORTING] CreateTwitterUserNewFriendsWorker is performed synchronously', request_id: id, uid: uid, context: context
      CreateTwitterUserNewFriendsWorker.new.perform(twitter_user_id)
    else
      # TODO Always run CreateTwitterUserNewFriendsWorker synchronously
      CreateTwitterUserNewFriendsWorker.perform_in(5.seconds, twitter_user_id)
    end
  end

  private

  def validate_request!
    raise AlreadyFinished if finished?
    raise Unauthorized if user && !user.authorized?
  end

  def validate_creation_interval!
    raise TooShortCreateInterval if TwitterUser.too_short_create_interval?(uid)
  end

  def build_snapshot(context)
    fetched_user = fetch_user
    raise SoftSuspended.new("screen_name=#{fetched_user[:screen_name]}") if fetched_user[:suspended]

    snapshot = TwitterSnapshot.new(fetched_user)
    relations = fetch_relations(snapshot, context)

    snapshot.friend_uids = relations[:friend_ids]
    snapshot.follower_uids = relations[:follower_ids]

    [snapshot, relations]
  rescue => e
    exception_handler(e)
    retry
  end

  def validate_twitter_user!(snapshot)
    if snapshot.friend_uids.any? { |uid| uid.nil? || uid == 0 }
      Airbag.warn 'validate_twitter_user!: friend_uids includes nil or 0', user_id: user_id, uid: uid
    end

    if snapshot.follower_uids.any? { |uid| uid.nil? || uid == 0 }
      Airbag.warn 'validate_twitter_user!: follower_uids includes nil or 0', user_id: user_id, uid: uid
    end

    if TwitterUser.exists?(uid: uid)
      if snapshot.too_little_friends?
        raise TooLittleFriends.new("no_friends_and_followers screen_name=#{snapshot.screen_name}")
      end

      if SearchLimitation.hard_limited?(snapshot)
        raise TooManyFriends.new("hard_limited screen_name=#{snapshot.screen_name}")
      end

      # TODO Implement #no_need_to_import_friendships? as class method
      if snapshot.no_need_to_import_friendships?
        raise TooManyFriends.new("already_exists screen_name=#{snapshot.screen_name}")
      end

      if diff_values_empty?(snapshot)
        raise NotChanged.new("empty_diff screen_name=#{snapshot.screen_name}")
      end
    end
  end

  def assemble_twitter_user(snapshot, relations)
    snapshot.user_timeline = relations[:user_timeline]
    snapshot.mention_tweets = collect_mention_tweets(relations[:mentions_timeline], relations[:search], snapshot.screen_name)
    snapshot.favorite_tweets = relations[:favorites]
    snapshot.user_id = user_id
  end

  def collect_mention_tweets(mentions, searched_tweets, screen_name)
    if mentions&.any?
      mentions
    elsif searched_tweets&.any?
      searched_tweets.reject { |status| uid == status[:user][:id] || status[:text].start_with?("RT @#{screen_name}") }
    else
      []
    end
  end

  def save_twitter_user(snapshot)
    twitter_user = TwitterUser.new(snapshot.attributes)
    twitter_user.perform_before_transaction
    twitter_user.save!

    if twitter_user.id.nil?
      raise SaveFailed.new("uid=#{twitter_user.uid} screen_name=#{twitter_user.screen_name}")
    end

    twitter_user.perform_after_commit
    update(twitter_user_id: twitter_user.id)
    twitter_user
  end

  def fetch_user
    client.user(uid)
  rescue => e
    if TwitterApiStatus.suspended?(e)
      raise HardSuspended.new("uid=#{uid}")
    elsif TwitterApiStatus.not_found?(e)
      raise NotFound.new("uid=#{uid}")
    else
      raise
    end
  end

  def fetch_relations(snapshot, context)
    client = (user || Bot).api_client(cache_store: :null_store)
    fetch_friends = !SearchLimitation.limited?(snapshot, signed_in: user)
    search_for_yourself = snapshot.uid == user&.uid
    reporting = context == :reporting

    fetcher = TwitterUserFetcher.new(client, snapshot.uid, snapshot.screen_name, fetch_friends, search_for_yourself, reporting)
    fetcher.fetch
  end

  def diff_values_empty?(twitter_user)
    TwitterUser.latest_by(uid: uid).diff(twitter_user).empty?
  end

  def exception_handler(e)
    if ServiceStatus.retryable_error?(e)
      @retries ||= 3
      if @retries <= 0
        raise RetryExhausted.new(e.inspect)
      else
        @retries -= 1
        return
      end
    end

    if e.is_a?(Error)
      raise e
    end

    if TwitterApiStatus.unauthorized?(e)
      raise Unauthorized
    elsif TwitterApiStatus.protected?(e)
      raise Protected
    elsif TwitterApiStatus.blocked?(e)
      raise Blocked
    elsif TwitterApiStatus.temporarily_locked?(e)
      raise TemporarilyLocked.new("uid=#{uid}")
    end

    if TwitterApiStatus.too_many_requests?(e)
      if user
        RateLimitExceededFlag.on(user.id)
      end
      raise TooManyRequests.new("user_id=#{user_id} api_name=#{@fetcher&.api_name}")
    end

    if TwitterApiStatus.retry_timeout?(e)
      raise HttpTimeout.new(e.inspect)
    end

    Airbag.info "#{self.class}##{__method__}: exception=#{e.inspect}#{" cause=#{e.cause.inspect}" if e.cause}", {backtrace: e.backtrace, cause_backtrace: e.cause&.backtrace}.compact
    raise Unknown.new(e.inspect)
  end

  def client
    @client ||= user ? user.api_client : Bot.api_client
  end

  class Error < StandardError; end

  class Unauthorized < Error; end

  class Forbidden < Error; end

  class SoftSuspended < Error; end

  class HardSuspended < Error; end

  class NotFound < Error; end

  class Protected < Error; end

  class Blocked < Error; end

  class TemporarilyLocked < Error; end

  class TooShortCreateInterval < Error; end

  class TooLittleFriends < Error; end

  class TooManyFriends < Error; end

  class NotChanged < Error; end

  class AlreadyFinished < Error; end

  class TooManyRequests < Error; end

  class ServiceUnavailable < Error; end

  class InternalServerError < Error; end

  class RetryExhausted < Error; end

  # TODO Remove later
  class TimeoutError < Error; end

  class HttpTimeout < Error; end

  class SaveFailed < Error; end

  class Unknown < StandardError; end
end
