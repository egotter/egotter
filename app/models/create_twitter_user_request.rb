# == Schema Information
#
# Table name: create_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  session_id      :string(191)
#  user_id         :integer          not null
#  uid             :bigint(8)        not null
#  twitter_user_id :integer
#  finished_at     :datetime
#  ahoy_visit_id   :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_create_twitter_user_requests_on_created_at  (created_at)
#  index_create_twitter_user_requests_on_user_id     (user_id)
#

class CreateTwitterUserRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user, optional: true
  belongs_to :twitter_user, optional: true

  validates :user_id, presence: true
  validates :uid, presence: true

  def perform!
    twitter_user = build_twitter_user

    # Don't call #invalid? because it clears errors
    raise RecordInvalid.new(twitter_user) if twitter_user.errors.any?

    if twitter_user.save
      update(twitter_user_id: twitter_user.id)
      CreateTwitterDBUserWorker.perform_async([uid])
      return twitter_user
    end

    if TwitterUser.exists?(uid: twitter_user.uid)
      raise NotChanged.new('After build')
    else
      raise RecordInvalid.new(twitter_user)
    end
  end

  def perform
    perform!
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    nil
  end

  # These validation methods (fresh?, no_need_to_import_friendships? and diff.empty?) are not implemented in
  # Rails default validation callbacks due to too heavy.
  def build_twitter_user
    latest = TwitterUser.latest_by(uid: uid)

    unless latest
      twitter_user = TwitterUser.build_by(user: fetch_user)
      relations = fetch_relations!(twitter_user)
      twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])
      twitter_user.build_other_relations(relations)
      twitter_user.user_id = user_id
      return twitter_user
    end

    raise RecentlyUpdated if latest.fresh?

    twitter_user = TwitterUser.build_by(user: fetch_user)
    relations = fetch_relations!(twitter_user)
    twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])

    if twitter_user.no_need_to_import_friendships?
      raise CreateTwitterUserRequest::TooManyFriends.new("Already exists. #{user_id}")
    end

    if latest.diff(twitter_user).empty?
      raise CreateTwitterUserRequest::NotChanged.new('Before build')
    end

    twitter_user.build_other_relations(relations)
    twitter_user.user_id = user_id
    twitter_user

  rescue Error => e
    raise
  rescue Twitter::Error::Forbidden => e
    if e.message.start_with? 'To protect our users from spam and other malicious activity, this account is temporarily locked.'
      raise Forbidden
    else
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      raise
    end
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise
  end

  def fetch_user
    @fetch_user ||= client.user(uid)
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      raise Unauthorized
    else
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      raise
    end
  end

  def fetch_relations!(twitter_user)
    @fetch_relations ||= TwitterUserFetcher.new(twitter_user, client: client, login_user: user).fetch
  end

  def client
    if instance_variable_defined?(:@client)
      @client
    else
      @client = user ? user.api_client : Bot.api_client
    end
  end

  class Error < StandardError
  end

  class Unauthorized < Error
    def initialize(*args)
      super('')
    end
  end

  class Forbidden < Error
    def initialize(*args)
      super('')
    end
  end

  class RecentlyUpdated < Error
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
end
