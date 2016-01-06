class TwitterUser < ActiveRecord::Base
  has_many :friends, foreign_key: :from_id, dependent: :destroy
  has_many :followers, foreign_key: :from_id, dependent: :destroy

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
    profile_image_url_https
    profile_banner_url
    suspended
  )

  def self.save_raw_user(data)
    if data.kind_of?(Twitter::User) || data.kind_of?(Hash) # TODO check keys and values
      create({
               uid: data.id,
               screen_name: data.screen_name,
               user_info: data.slice(*SAVE_KEYS).to_json})
    else
      raise
    end
  end

  def save_raw_friends(data)
    if data.kind_of?(Array) && (data.first.kind_of?(Twitter::User) || data.first.kind_of?(Hash))
      _data = data.map do |d|
        {uid: d.id,
         screen_name: d.screen_name,
         user_info: d.slice(*SAVE_KEYS).to_json}
      end
      friends.create(_data)
    else
      raise
    end
  end

  def save_raw_followers(data)
    if data.kind_of?(Array) && (data.first.kind_of?(Twitter::User) || data.first.kind_of?(Hash))
      _data = data.map do |d|
        {uid: d.id,
         screen_name: d.screen_name,
         user_info: d.slice(*SAVE_KEYS).to_json}
      end
      followers.create(_data)
    else
      raise
    end
  end
end
