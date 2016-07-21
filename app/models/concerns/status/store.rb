require 'active_support/concern'

module Concerns::Status::Store
  extend ActiveSupport::Concern

  # https://dev.twitter.com/overview/api/tweets
  STATUS_SAVE_KEYS = %i(
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

  STATUS_REJECT_KEYS = %i(id screen_name created_at)

  METHOD_NAME_KEYS = STATUS_SAVE_KEYS.reject { |k| k.in?(STATUS_REJECT_KEYS) }

  included do
    delegate *METHOD_NAME_KEYS, to: :_status_info
    # store :status_info, accessors: METHOD_NAME_KEYS, coder: JSON
  end

  def _status_info
    @_status_info ||= Hashie::Mash.new(JSON.load(status_info))
  end

  def mentions?
    entities.present? && entities.user_mentions.present? && entities.user_mentions.any?
  end

  def media?
    entities.present? && entities.media.present? && entities.media.any?
  end

  def urls?
    entities.present? && entities.urls.present? && entities.urls.any?
  end

  def hashtags?
    entities.present? && entities.hashtags.present? && entities.hashtags.any?
  end

  def hashtags
    entities.hashtags.map { |h| h.text }
  end

  def location?
    !coordinates.nil?
  end
end