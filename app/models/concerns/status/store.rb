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

  STATUS_REJECT_KEYS = %i(id screen_name user entities created_at)

  included do
    store :status_info, accessors: STATUS_SAVE_KEYS.reject { |k| k.in?(STATUS_REJECT_KEYS) }, coder: JSON
  end

  %i(user entities).each do |method_name|
    define_method method_name do
      Hashie::Mash.new(status_info[method_name])
    end
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