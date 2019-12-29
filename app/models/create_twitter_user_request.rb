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

  def perform!
    raise Unauthorized if user&.unauthorized?

    twitter_user = build_twitter_user

    # Don't call #invalid? because it clears errors
    raise RecordInvalid.new(twitter_user) if twitter_user.errors.any?

    if twitter_user.save
      update(twitter_user_id: twitter_user.id)
      return twitter_user
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
  def build_twitter_user
    previous_twitter_user = TwitterUser.latest_by(uid: uid)

    unless previous_twitter_user
      fetched_user = twitter_user = relations = nil
      benchmark('fetch_user') { fetched_user = fetch_user }
      benchmark('TwitterUser.build_by') { twitter_user = TwitterUser.build_by(user: fetched_user) }
      benchmark('fetch_relations!', twitter_user) { relations = fetch_relations!(twitter_user) }
      benchmark('build_friends_and_followers', twitter_user) { twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids]) }
      benchmark('build_other_relations', twitter_user) { twitter_user.build_other_relations(relations) }
      twitter_user.user_id = user_id
      return twitter_user
    end

    # The purpose of this code is to determine as soon as possible whether a record can be created.

    raise TooShortCreateInterval if previous_twitter_user.too_short_create_interval?

    fetched_user = current_twitter_user = relations = nil
    benchmark('fetch_user') { fetched_user = fetch_user }
    benchmark('TwitterUser.build_by') { current_twitter_user = TwitterUser.build_by(user: fetched_user) }
    benchmark('fetch_relations!', current_twitter_user) { relations = fetch_relations!(current_twitter_user) }
    benchmark('build_friends_and_followers', current_twitter_user) { current_twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids]) }

    if current_twitter_user.no_need_to_import_friendships?
      raise TooManyFriends.new('Already exists')
    end

    diff_not_found = false
    benchmark('diff', current_twitter_user) { diff_not_found = previous_twitter_user.diff(current_twitter_user).empty? }

    if diff_not_found
      raise NotChanged.new('Before build')
    end

    benchmark('build_other_relations', current_twitter_user) { current_twitter_user.build_other_relations(relations) }
    current_twitter_user.user_id = user_id
    current_twitter_user

  rescue Error => e
    raise
  rescue Twitter::Error::TooManyRequests => e
    raise
  rescue Twitter::Error::Forbidden => e
    if e.message.start_with? 'To protect our users from spam and other malicious activity, this account is temporarily locked.'
      raise Forbidden
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  rescue => e
    if AccountStatus.unauthorized?(e)
      raise Unauthorized
    elsif AccountStatus.protected?(e)
      raise Protected
    elsif ServiceStatus.service_unavailable?(e)
      raise ServiceUnavailable
    elsif ServiceStatus.internal_server_error?(e)
      raise InternalServerError
    elsif e.message == 'Connection reset by peer'
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

  def fetch_relations!(twitter_user)
    @fetch_relations ||= TwitterUserFetcher.new(twitter_user, client: client, login_user: user).fetch
  end

  def client
    @client ||= user ? user.api_client : Bot.api_client
  end

  def benchmark(message, twitter_user = nil, &block)
    ApplicationRecord.benchmark("Benchmark CreateTwitterUserRequest #{user_id} #{uid} #{message} friends=#{twitter_user&.friends_count} followers=#{twitter_user&.followers_count}", level: :info, &block)
  end

  class Error < StandardError
  end

  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class Protected < Error
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

  class TooManyRequests < Error
  end

  class ServiceUnavailable < Error
  end

  class InternalServerError < Error
  end

  class Unknown < StandardError
  end
end
