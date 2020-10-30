# == Schema Information
#
# Table name: create_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  session_id      :string(191)
#  user_id         :integer          not null
#  uid             :bigint(8)        not null
#  twitter_user_id :integer
#  requested_by    :string(191)      default(""), not null
#  finished_at     :datetime
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
    def too_short_request_interval?(uid:)
      where(created_at: 1.minute.ago..Time.zone.now).where(uid: uid).exists?
    end
  end

  # context:
  #   :reporting
  def perform!(context = nil)
    validate_request!
    validate_creation_interval!

    snapshot, relations = build_snapshot(context)
    validate_creation_interval!
    validate_twitter_user!(snapshot)

    assemble_twitter_user(snapshot, relations)
    validate_creation_interval!
    save_twitter_user(snapshot)
  end

  private

  def validate_request!
    raise AlreadyFinished if finished?
    raise Unauthorized if user && !user.authorized?
  end

  def validate_creation_interval!
    # TODO Implement #too_short_create_interval? as class method
    raise TooShortCreateInterval if TwitterUser.select(:id, :created_at).latest_by(uid: uid)&.too_short_create_interval?
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

  def validate_twitter_user!(twitter_user)
    if twitter_user.friend_uids.any? { |uid| uid.nil? || uid == 0 }
      Rails.logger.warn "#{self.class}##{__method__} friend_uids includes nil or 0 user_id=#{user_id} uid=#{uid}"
    end

    if twitter_user.follower_uids.any? { |uid| uid.nil? || uid == 0 }
      Rails.logger.warn "#{self.class}##{__method__} follower_uids includes nil or 0 user_id=#{user_id} uid=#{uid}"
    end

    if TwitterUser.exists?(uid: uid)
      if twitter_user.too_little_friends?
        raise TooLittleFriends.new("no_friends_and_followers screen_name=#{twitter_user.screen_name}")
      end

      if SearchLimitation.hard_limited?(twitter_user)
        raise TooManyFriends.new("hard_limited screen_name=#{twitter_user.screen_name}")
      end

      # TODO Implement #no_need_to_import_friendships? as class method
      if twitter_user.no_need_to_import_friendships?
        raise TooManyFriends.new("already_exists screen_name=#{twitter_user.screen_name}")
      end

      if diff_values_empty?(twitter_user)
        raise NotChanged.new("empty_diff screen_name=#{twitter_user.screen_name}")
      end
    end
  end

  def assemble_twitter_user(twitter_user, relations)
    twitter_user.user_timeline = relations[:user_timeline]
    twitter_user.mention_tweets = collect_mention_tweets(relations[:mentions_timeline], relations[:search], twitter_user.screen_name)
    twitter_user.favorite_tweets = relations[:favorites]
    twitter_user.user_id = user_id
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
    twitter_user = snapshot.copy
    twitter_user.save!
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
    unless @fetcher
      fetch_friends = !SearchLimitation.limited?(snapshot, signed_in: user)
      search_for_yourself = snapshot.uid == user&.uid
      reporting = context == :reporting
      # TODO Try disabling the cache for speed
      @fetcher = TwitterUserFetcher.new(client, snapshot.uid, snapshot.screen_name, fetch_friends, search_for_yourself, reporting)
    end
    @fetcher.fetch_in_threads
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
        TooManyRequestsUsers.new.add(user.id)
        ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user.id)
      end
      raise TooManyRequests.new("user_id=#{user_id} api_name=#{@fetcher&.api_name}")
    end

    raise Unknown.new(e.inspect)
  end

  def client
    @client ||= user ? user.api_client : Bot.api_client
  end

  module Instrumentation
    %i(
      fetch_user
      build_snapshot
      fetch_relations
      diff_values_empty?
      save_twitter_user
    ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        bm_perform(method_name) { method(method_name).super_method.call(*args, &blk) }
      end
    end

    def bm_perform(message, &block)
      start = Time.zone.now
      result = yield
      @bm_perform[message] = Time.zone.now - start if @bm_perform
      result
    end

    def perform!(*args, &blk)
      @bm_perform = {}
      start = Time.zone.now

      result = super

      elapsed = Time.zone.now - start
      @bm_perform['sum'] = @bm_perform.values.sum
      @bm_perform['elapsed'] = elapsed

      Rails.logger.info "Benchmark CreateTwitterUserRequest user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)} #{@bm_perform.inspect}"

      result
    end
  end
  prepend Instrumentation

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

  class Unknown < StandardError; end
end
