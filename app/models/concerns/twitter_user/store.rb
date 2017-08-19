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

  PROFILE_REJECT_KEYS = %i(
    id
    screen_name
    url
    created_at
  )

  METHOD_NAME_KEYS = PROFILE_SAVE_KEYS.reject { |k| k.in?(PROFILE_REJECT_KEYS) }

  TIME_ZONE_MAPPING = {
    'JST' => 'Asia/Tokyo',
    'GMT+9' => 'Asia/Tokyo',
    'Ulaan Bataar' => 'Asia/Ulaanbaatar',
    'GMT-8' => 'America/Los_Angeles',
    'Kiev' => 'Europe/Kiev',
    'GMT-4' => 'America/Puerto_Rico'
  }

  class_methods do
    def collect_user_info(t_user)
      t_user.slice(*PROFILE_SAVE_KEYS).to_json
    end
  end

  included do
    delegate *METHOD_NAME_KEYS, to: :_user_info
    # store :user_info, accessors: METHOD_NAME_KEYS, coder: JSON
  end

  def _user_info
    @_user_info ||= Hashie::Mash.new(JSON.load(user_info))
  end

  # a url written on profile page as home page url
  def url
    return nil if entities.nil? || entities.url.nil? || entities.url.urls.nil?

    urls = entities.url.urls
    urls.any? ? (urls[0].expanded_url || urls[0].url) : nil
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{entities}"
    nil
  end

  def inactive
    TwitterUser.inactive_user?(self)
  end

  def account_created_at
    at = _user_info[:created_at].to_s
    if time_zone.present? && at.present?
      ActiveSupport::TimeZone[TIME_ZONE_MAPPING[time_zone.to_s] || time_zone.to_s].parse(at)
    elsif at.present?
      Time.zone.parse(at)
    else
      nil
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} [#{time_zone}] [#{at}]"
    nil
  end
end
