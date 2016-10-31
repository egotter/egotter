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

  PROFILE_REJECT_KEYS = %i(id screen_name url created_at)

  METHOD_NAME_KEYS = PROFILE_SAVE_KEYS.reject { |k| k.in?(PROFILE_REJECT_KEYS) }

  JAPANESE_TIME_ZONE_NAMES = %w(JST GMT+9)

  included do
    delegate *METHOD_NAME_KEYS, to: :_user_info
    # store :user_info, accessors: METHOD_NAME_KEYS, coder: JSON
  end

  def _user_info
    @_user_info ||= Hashie::Mash.new(JSON.load(user_info))
  end

  def url
    return nil if entities.nil? || entities.url.nil? || entities.url.urls.nil?

    urls = entities.url.urls
    urls.any? ? (urls[0].expanded_url || urls[0].url) : nil
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{entities}"
    nil
  end

  def twittered_at
    account_created_at = _user_info[:created_at]
    if time_zone.present? && account_created_at.present?
      _time_zone = (time_zone.in?(JAPANESE_TIME_ZONE_NAMES) ? 'Tokyo' : time_zone)
      ActiveSupport::TimeZone[_time_zone].parse(account_created_at)
    elsif account_created_at.present?
      Time.zone.parse(account_created_at)
    else
      account_created_at
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} [#{time_zone}] [#{account_created_at}]"
    account_created_at
  end
end