require 'active_support/concern'

module Concerns::TwitterUser::RawAttrs
  extend ActiveSupport::Concern

  SAVE_KEYS = %i(
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

  REJECT_KEYS = %i(
    id
    screen_name
    followers_count
    friends_count
    url
    created_at
  )

  METHOD_NAME_KEYS = SAVE_KEYS.reject { |k| k.in?(REJECT_KEYS) }

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
      t_user.symbolize_keys.slice(*SAVE_KEYS).to_json
    end
  end

  included do
    attr_accessor :raw_attrs_text

    delegate *METHOD_NAME_KEYS, to: :raw_attrs
  end

  # A url written on profile page as a home page url
  def url
    return nil if entities.nil? || entities.url.nil? || entities.url.urls.nil?

    urls = entities.url.urls
    urls.any? ? (urls[0].expanded_url || urls[0].url) : nil
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{entities}"
    nil
  end

  def account_created_at
    at = raw_attrs[:created_at].to_s
    if time_zone.present? && at.present?
      ActiveSupport::TimeZone[TIME_ZONE_MAPPING[time_zone.to_s] || time_zone.to_s].parse(at)
    elsif at.present?
      Time.zone.parse(at)
    else
      nil
    end
  rescue => e
    logger.info "#{self.class}##{__method__}: #{e.class} #{e.message} [#{time_zone}] [#{at}]"
    nil
  end

  def profile_not_found?
    if instance_variable_defined?(:@profile_not_found)
      @profile_not_found
    else
      raw_attrs
      @profile_not_found
    end
  end

  private

  def raw_attrs
    if new_record?
      attrs = nil
      begin
        attrs = Oj.load(raw_attrs_text.presence || '{}', symbol_keys: true)
      rescue => e
        attrs = {}
      end
      Hashie::Mash.new(attrs)
    else
      if instance_variable_defined?(:@raw_attrs)
        @raw_attrs
      else
        profile = Efs::TwitterUser.find_by(id)&.fetch(:profile, nil)
        profile = Oj.load(profile, symbol_keys: true) if profile.class == String # Fix me.
        if profile && profile.class == Hash && !profile.blank?
          @profile_not_found = false
          return (@raw_attrs = Hashie::Mash.new(profile))
        end

        profile = S3::Profile.find_by(twitter_user_id: id)
        if !profile.blank? && !profile[:user_info].blank?
          profile = Oj.load(profile[:user_info], symbol_keys: true)
          @profile_not_found = false
          return (@raw_attrs = Hashie::Mash.new(profile))
        end

        logger.warn "Profile not found in EFS and S3. #{id} #{sprintf("%.3f sec", Time.zone.now - created_at)}"

        @profile_not_found = true
        @raw_attrs = Hashie::Mash.new({})
      end
    end
  end
end
