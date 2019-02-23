require 'active_support/concern'

module Concerns::TwitterDB::Status::RawAttrs
  extend ActiveSupport::Concern

  # https://dev.twitter.com/overview/api/tweets
  # 'user' is used in #replied_uids
  SAVE_KEYS = %i(
    created_at
    id
    text
    source
    truncated
    coordinates
    place
    entities
    user
    contributors
    is_quote_status
    retweet_count
    favorite_count
    favorited
    retweeted
    possibly_sensitive
    lang
  )

  REJECT_KEYS = %i(id screen_name created_at)

  included do
    delegate *SAVE_KEYS.reject {|k| k.in?(REJECT_KEYS)}, to: :raw_attrs
  end

  def raw_attrs
    @raw_attrs ||= Hashie::Mash.new(JSON.load(raw_attrs_text))
  end

  def mentions?
    entities&.user_mentions&.any?
  end

  def media?
    entities&.media&.any?
  end

  def urls?
    entities&.urls&.any?
  end

  def hashtags?
    entities&.hashtags&.any?
  end

  def hashtags
    entities.hashtags.map {|h| h.text}
  end

  def location?
    !coordinates.nil?
  end

  def tweet_id
    raw_attrs.id
  end

  def tweeted_at
    # TODO Use user specific time zone
    ActiveSupport::TimeZone['Tokyo'].parse(raw_attrs.created_at)
  end

  def retweet?
    text.start_with? 'RT'
  end

  def mention_uids
    # statuses.map { |status| status.entities&.user_mentions&.map { |obj| obj['id'] } }&.flatten.compact
    # statuses.map { |status| $1 if status.text.match /^(?:\.)?@(\w+)( |\W)/ }.compact
    entities&.user_mentions&.map {|obj| obj['id']}&.compact
  end

  def mention_to?(mention_name)
    !retweet? && text.include?(mention_name)
  end
end
