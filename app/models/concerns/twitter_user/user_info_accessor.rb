require 'active_support/concern'

module Concerns::TwitterUser::UserInfoAccessor
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

  included do
    delegate *PROFILE_SAVE_KEYS.reject { |k| k.in?(PROFILE_REJECT_KEYS) }, to: :user_info_mash

    def user_info_mash
      return @user_info_mash if @user_info_mash.present?
      if user_info.present?
        @user_info_mash = Hashie::Mash.new(JSON.parse(user_info))
      else
        Hashie::Mash.new(JSON.parse('{"friends_count": -1, "followers_count": -1}'))
      end
    end

    def has_key?(key)
      user_info_mash.has_key?(key)
    end

    def url
      urls = user_info_mash.entities!.url!.urls
      return nil if urls.nil?
      urls.any? ? (urls[0].expanded_url || urls[0].url) : nil
    rescue => e
      logger.warn "#{e.class} #{e.message} #{user_info_mash.entities}"
      nil
    end

    def twittered_at
      if time_zone.present? && user_info_mash.created_at.present?
        _time_zone = (time_zone == 'JST' ? 'Tokyo' : time_zone)
        ActiveSupport::TimeZone[_time_zone].parse(user_info_mash.created_at)
      elsif user_info_mash.created_at.present?
        Time.zone.parse(user_info_mash.created_at)
      else
        user_info_mash.created_at
      end
    rescue => e
      logger.warn "#{e}: #{e.message} #{time_zone}, #{user_info_mash.created_at}"
      logger.warn e.backtrace.join("\n")
      user_info_mash.created_at
    end

  end
end