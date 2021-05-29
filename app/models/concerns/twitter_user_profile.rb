require 'active_support/concern'

module TwitterUserProfile
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

  def url
    entities[:url][:urls][0][:expanded_url]
  rescue => e
    profile[:url]
  end

  def account_created_at
    time = profile[:created_at].to_s

    if time_zone.present? && time.present?
      rails_time_zone = ActiveSupport::TimeZone[TIME_ZONE_MAPPING[time_zone] || time_zone]
      rails_time_zone.parse(time)
    elsif time.present?
      Time.zone.parse(time)
    else
      nil
    end
  rescue => e
    logger.info "#{self.class}##{__method__}: #{e.class} #{e.message} [#{time_zone}] [#{time}]"
    nil
  end

  def status_created_at
    status&.created_at
  end

  def profile_not_found?
    profile.blank?
  end

  private

  def profile
    if new_record?
      # #build_twitter_user_by_uid in WaitingController returns new record and
      # profile header on #new action renders the record
      begin
        attrs = Oj.strict_load(profile_text.presence || '{}')
      rescue => e
        attrs = {}
      end
      Hashie::Mash.new(attrs)
    else
      if instance_variable_defined?(:@profile)
        @profile
      else
        if (hash = fetch_profile).blank?
          @profile = Hashie::Mash.new({})
        else
          hash = Oj.strict_load(hash, symbol_keys: true) if hash.class == String
          @profile = Hashie::Mash.new(hash)
        end
      end
    end
  end

  def fetch_profile
    data = nil
    exceptions = []

    begin
      data = InMemory::TwitterUser.find_by(id)&.profile if InMemory.enabled? && InMemory.cache_alive?(created_at) # Hash
    rescue => e
      exceptions << e
    end

    begin
      data = Efs::TwitterUser.find_by(id)&.profile if data.blank? && Efs.enabled? # Hash
    rescue => e
      exceptions << e
    end

    begin
      data = S3::Profile.find_by(twitter_user_id: id)&.fetch(:user_info, nil) if data.blank? # String
    rescue => e
      exceptions << e
    end

    if data.blank?
      Rails.logger.warn "Fetching profile is failed. id=#{id} screen_name=#{screen_name} created_at=#{created_at.to_s(:db)} exceptions=#{exceptions.inspect}"
      Rails.logger.info caller.join("\n")
    end

    data
  end
end
