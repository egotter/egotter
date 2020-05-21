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
#  diff_keys       :string(191)
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
    raise AlreadyFinished if finished?
    raise Unauthorized if user&.unauthorized?

    twitter_user = build_twitter_user(context)

    # Don't call #invalid? because it clears errors
    raise RecordInvalid.new(twitter_user) if twitter_user.errors.any?

    save_result = nil
    bm_perform('twitter_user.save') { save_result = twitter_user.save }
    if save_result
      update(twitter_user_id: twitter_user.id)
      logger.debug { "CreateTwitterUserRequest record created twitter_user_id=#{twitter_user.id}" }
      return twitter_user
    else
      logger.debug { "CreateTwitterUserRequest record NOT created" }
    end

    if TwitterUser.exists?(uid: twitter_user.uid)
      raise NotChanged.new('After build')
    else
      raise RecordInvalid.new(twitter_user)
    end
  end

  # These methods are not registered as validation callbacks due to too heavy.
  #
  # #too_short_create_interval?
  # #no_need_to_import_friendships?
  # #diff.empty?
  #
  def build_twitter_user(context = nil)
    previous_twitter_user = TwitterUser.latest_by(uid: uid)

    unless previous_twitter_user
      fetched_user = twitter_user = relations = nil
      bm_perform('fetch_user') { fetched_user = fetch_user }
      bm_perform('TwitterUser.build_by') { twitter_user = TwitterUser.build_by(user: fetched_user) }
      bm_perform('fetch_relations!') { relations = fetch_relations!(twitter_user, context) }
      bm_perform('build_friends_and_followers') { twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids]) }
      bm_perform('build_other_relations') { twitter_user.build_other_relations(relations) }
      twitter_user.user_id = user_id
      return twitter_user
    end

    # The purpose of this code is to determine as soon as possible whether a record can be created.

    raise TooShortCreateInterval if previous_twitter_user.too_short_create_interval?

    fetched_user = current_twitter_user = relations = nil
    bm_perform('fetch_user') { fetched_user = fetch_user }
    bm_perform('TwitterUser.build_by') { current_twitter_user = TwitterUser.build_by(user: fetched_user) }
    bm_perform('fetch_relations!') { relations = fetch_relations!(current_twitter_user, context) }
    bm_perform('build_friends_and_followers') { current_twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids]) }

    if current_twitter_user.no_need_to_import_friendships?
      raise TooManyFriends.new('Already exists')
    end

    diff_not_found = false
    bm_perform('diff') { diff_not_found = previous_twitter_user.diff(current_twitter_user).empty? }

    if diff_not_found
      raise NotChanged.new('Before build')
    end

    bm_perform('build_other_relations') { current_twitter_user.build_other_relations(relations) }
    current_twitter_user.user_id = user_id
    current_twitter_user

  rescue TooShortCreateInterval, TooManyFriends, NotChanged => e
    raise
  rescue Twitter::Error::TooManyRequests => e
    raise
  rescue => e
    if AccountStatus.unauthorized?(e)
      raise Unauthorized
    elsif AccountStatus.protected?(e)
      raise Protected
    elsif AccountStatus.blocked?(e)
      raise Blocked
    elsif AccountStatus.temporarily_locked?(e)
      raise TemporarilyLocked
    elsif ServiceStatus.service_unavailable?(e)
      raise ServiceUnavailable
    elsif ServiceStatus.internal_server_error?(e)
      raise InternalServerError
    elsif ServiceStatus.connection_reset_by_peer?(e)
      retry
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  def fetch_user
    @fetch_user ||= client.user(uid)
  rescue => e
    if AccountStatus.unauthorized?(e)
      raise Unauthorized
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  def fetch_relations!(twitter_user, context)
    @fetch_relations ||= TwitterUserFetcher.new(twitter_user, client: client, login_user: user, context: context).fetch
  end

  def client
    @client ||= user ? user.api_client : Bot.api_client
  end

  module Instrumentation
    def bm_perform(message, &block)
      start = Time.zone.now
      yield
      @bm_perform[message] = Time.zone.now - start
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

  class Unknown < StandardError
  end
end
