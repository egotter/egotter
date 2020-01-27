require 'active_support/concern'

module Concerns::TwitterUser::Profile
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

  included do
    attr_accessor :profile_text

    delegate *METHOD_NAME_KEYS, to: :profile
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
    profile.blank?
  end

  private

  def profile
    if new_record?
      begin
        attrs = Oj.load(profile_text.presence || '{}')
      rescue => e
        attrs = {}
      end
      Hashie::Mash.new(attrs)
    else
      if instance_variable_defined?(:@profile)
        @profile
      else
        if (text = fetch_profile_text).blank?
          logger.warn "Profile not found in EFS and S3. #{id} #{sprintf("%.3f sec", Time.zone.now - created_at)}"
          @profile = Hashie::Mash.new({})
        else
          text = Oj.load(text, symbol_keys: true) if text.class == String
          @profile = Hashie::Mash.new(text)
        end
      end
    end
  end

  def fetch_profile_text
    text = Efs::TwitterUser.find_by(id)&.fetch(:profile, nil) # Hash
    text = S3::Profile.find_by(twitter_user_id: id)&.fetch(:user_info, nil) if text.blank? # String
    text
  end
end
