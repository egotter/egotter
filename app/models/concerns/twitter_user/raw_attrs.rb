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

  def inactive?
    status&.created_at && Time.parse(status.created_at) < 2.weeks.ago
  end

  # Used in view
  def inactive
    inactive?
  end

  def load_raw_attrs_text_from_s3!
    profile = S3::Profile.find_by(twitter_user_id: id)
    if profile.empty?
      raise S3::Profile::MaybeFetchFailed
    end

    text = profile[:user_info]
    if text.blank? || text == '{}'
      logger.warn {"S3::Profile[:user_info] is blank. #{id}"}
      text = '{}'
    end

    @raw_attrs = Hashie::Mash.new(JSON.parse(text))
  end

  def load_raw_attrs_text_from_s3
    load_raw_attrs_text_from_s3!
  rescue => e
    @raw_attrs = Hashie::Mash.new({})
  end

  private

  def raw_attrs
    if new_record?
      Hashie::Mash.new(JSON.parse(raw_attrs_text))
    else
      if instance_variable_defined?(:@raw_attrs)
        @raw_attrs
      else
        load_raw_attrs_text_from_s3
      end
    end
  end
end
