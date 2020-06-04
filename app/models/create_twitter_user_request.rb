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
  include Concerns::Request::Runnable
  belongs_to :user, optional: true
  belongs_to :twitter_user, optional: true

  validates :user_id, presence: true
  validates :uid, presence: true

  # context:
  #   :prompt_reports
  #   :periodic_reports
  def perform!(context = nil)
    validate_request!

    twitter_user, relations = build_twitter_user(context)
    validate_twitter_user!(twitter_user)

    assemble_twitter_user(twitter_user, relations)
    save_twitter_user(twitter_user)

    twitter_user
  end

  def validate_request!
    raise AlreadyFinished if finished?
    raise Unauthorized if user&.unauthorized?
    # TODO Implement #too_short_create_interval? as class method
    raise TooShortCreateInterval if TwitterUser.select(:id, :created_at).latest_by(uid: uid)&.too_short_create_interval?
  end

  def build_twitter_user(context = nil)
    fetched_user = fetch_user
    twitter_user = build_twitter_user_by(fetched_user)
    relations = fetch_relations(twitter_user, context)

    attach_friend_uids(twitter_user, relations[:friend_ids])
    attach_follower_uids(twitter_user, relations[:follower_ids])

    [twitter_user, relations]
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
        raise TooLittleFriends.new('no_friends_and_followers')
      end

      if SearchLimitation.hard_limited?(twitter_user)
        raise TooManyFriends.new('hard_limited')
      end

      # TODO Implement #no_need_to_import_friendships? as class method
      if twitter_user.no_need_to_import_friendships?
        raise TooManyFriends.new('Already exists')
      end

      if diff_values_empty?(twitter_user)
        raise NotChanged.new('Before build')
      end
    end
  end

  def assemble_twitter_user(twitter_user, relations)
    attach_user_timeline(twitter_user, relations[:user_timeline])
    attach_mentions_timeline(twitter_user, relations[:mentions_timeline], relations[:search])
    attach_favorite_tweets(twitter_user, relations[:favorites])

    twitter_user.user_id = user_id
  end

  def save_twitter_user(twitter_user)
    twitter_user.save!
    update(twitter_user_id: twitter_user.id)
  end

  def fetch_user
    @fetch_user ||= client.user(uid)
  end

  def build_twitter_user_by(user)
    TwitterUser.build_by(user: user)
  end

  def fetch_relations(twitter_user, context)
    @fetch_relations ||= TwitterUserFetcher.new(twitter_user, login_user: user, context: context).fetch
  end

  def attach_friend_uids(twitter_user, uids)
    twitter_user.attach_friend_uids(uids)
  end

  def attach_follower_uids(twitter_user, uids)
    twitter_user.attach_follower_uids(uids)
  end

  def attach_user_timeline(twitter_user, tweets)
    twitter_user.attach_user_timeline(tweets)
  end

  def attach_mentions_timeline(twitter_user, tweets, search_result)
    twitter_user.attach_mentions_timeline(tweets, search_result)
  end

  def attach_favorite_tweets(twitter_user, tweets)
    twitter_user.attach_favorite_tweets(tweets)
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

    if AccountStatus.unauthorized?(e)
      raise Unauthorized
    elsif AccountStatus.protected?(e)
      raise Protected
    elsif AccountStatus.blocked?(e)
      raise Blocked
    elsif AccountStatus.temporarily_locked?(e)
      raise TemporarilyLocked
    end

    raise Unknown.new(e.inspect)
  end

  def client
    @client ||= user ? user.api_client : Bot.api_client
  end

  module Instrumentation
    %i(
      fetch_user
      build_twitter_user_by
      fetch_relations
      attach_friend_uids
      attach_follower_uids
      attach_user_timeline
      attach_mentions_timeline
      attach_favorite_tweets
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

      Rails.logger.info "Benchmark CreateTwitterUserRequest user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)}"
      Rails.logger.info "Benchmark CreateTwitterUserRequest user_id=#{user_id} uid=#{uid} #{@bm_perform.inspect}"

      result
    end
  end
  prepend Instrumentation

  class Error < StandardError
  end

  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class Protected < Error
  end

  class Blocked < Error
  end

  class TemporarilyLocked < Error
  end

  class TooShortCreateInterval < Error
  end

  class TooLittleFriends < Error
  end

  class TooManyFriends < Error
  end

  class RecordInvalid < Error
    def initialize(record)
      super(record.errors.full_messages.join(', '))
    end
  end

  class NotChanged < Error
  end

  class AlreadyFinished < Error
  end

  class TooManyRequests < Error
  end

  class ServiceUnavailable < Error
  end

  class InternalServerError < Error
  end

  class RetryExhausted < Error
  end

  class Unknown < StandardError
  end
end
