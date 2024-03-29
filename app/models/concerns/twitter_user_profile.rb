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
    Time.zone.parse(profile[:created_at])
  rescue => e
    Airbag.info "account_created_at: #{e.message}", time: profile[:created_at], exception: e.inspect
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
    source = nil
    start = Time.zone.now

    begin
      if InMemory.enabled? && InMemory.cache_alive?(created_at)
        data = InMemory::TwitterUser.find_by(id)&.profile # Hash
        source = 'memory'
      end
    rescue => e
      exceptions << e
    end

    begin
      if data.blank? && Efs.enabled?
        data = Efs::TwitterUser.find_by(id)&.profile # Hash
        source = 'efs'
      end
    rescue => e
      exceptions << e
    end

    begin
      if data.blank?
        data = S3::Profile.find_by(twitter_user_id: id)&.fetch(:user_info, nil) # String
        source = 's3'
      end
    rescue => e
      exceptions << e
    end

    if data.blank?
      Airbag.warn 'Fetching profile failed', twitter_user_id: id, uid: uid, created_at: created_at.to_s(:db), exceptions: exceptions.inspect, caller: caller
    else
      Airbag.info 'Fetching profile succeeded', twitter_user_id: id, uid: uid, source: source, elapsed: (Time.zone.now - start) if Rails.env.development?
    end

    data
  end
end
