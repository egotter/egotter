require 'active_support/concern'

module Concerns::TwitterUser::Store
  extend ActiveSupport::Concern

  PROFILE_SAVE_KEYS = %i(
      id
      name
      screen_name
      location
      description
      url
      protected
      followers_count
      friends_count
      listed_count
      favourites_count
      utc_offset
      time_zone
      geo_enabled
      verified
      statuses_count
      lang
      status
      profile_image_url_https
      profile_banner_url
      profile_link_color
      suspended
      verified
      entities
      created_at
    )

  PROFILE_REJECT_KEYS = %i(id screen_name url status entities created_at)

  JAPANESE_TIME_ZONE_NAMES = %w(JST GMT+9)

  included do
    store :user_info, accessors: PROFILE_SAVE_KEYS.reject { |k| k.in?(PROFILE_REJECT_KEYS) }, coder: JSON
  end

  %i(status entities).each do |method_name|
    define_method method_name do
      Hashie::Mash.new(user_info[method_name])
    end
  end

  def url
    _entities = Hashie::Mash.new(entities)
    return nil if _entities.nil? || _entities.url.nil? || _entities.url.urls.nil?

    urls = _entities.url.urls
    urls.any? ? (urls[0].expanded_url || urls[0].url) : nil
  rescue => e
    logger.warn "#{e}: #{e.message} #{entities}"
    nil
  end

  def twittered_at
    _created_at = user_info[:created_at]
    if time_zone.present? && _created_at.present?
      _time_zone = (time_zone.in?(JAPANESE_TIME_ZONE_NAMES) ? 'Tokyo' : time_zone)
      ActiveSupport::TimeZone[_time_zone].parse(_created_at)
    elsif _created_at.present?
      Time.zone.parse(_created_at)
    else
      _created_at
    end
  rescue => e
    logger.warn "#{e}: #{e.message} #{time_zone}, #{_created_at}"
    logger.warn e.backtrace.join("\n")
    _created_at
  end
end