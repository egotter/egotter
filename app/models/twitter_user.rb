# == Schema Information
#
# Table name: twitter_users
#
#  id          :integer          not null, primary key
#  uid         :string           not null
#  screen_name :string           not null
#  user_info   :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_screen_name  (screen_name)
#  index_twitter_users_on_uid          (uid)
#

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

  delegate *SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :user_info_mash

  def user_info_mash
    @user_info_hash ||= Hashie::Mash.new(JSON.parse(user_info))
  end

  validate :allow_to_create?

  def allow_to_create?
    me = latest_me
    return true if me.blank?
    if me.recently_created? || me.recently_updated?
      errors[:base] << 'recently_created? or recently_updated? is true'
      return false
    end
    latest_me.different_from?(self)
  end

  def different_from?(other)
    raise 'something is wrong' if self.new_record?
    raise 'something is wrong' if other.persisted?
    raise 'something is wrong' if self.uid != other.uid

    if self.friends_count != other.friends_count || self.followers_count != other.followers_count
      errors[:base] << 'friends_count or followers_count is different'
      return false
    end

    if self.friends.pluck(:uid).map { |uid| uid.to_i }.sort != other.friends.map { |f| f.uid.to_i }.sort ||
      self.followers.pluck(:uid).map { |uid| uid.to_i }.sort != other.followers.map { |f| f.uid.to_i }.sort
      errors[:base] << 'friends or followers are different'
      return false
    end

    true
  end

  def self.build_with_raw_twitter_data(client, uid, option = {})
    option = {all: true} if option.blank?

    # call 2 times to use cache
    _raw_me = client.user(uid.to_i) && client.user(uid.to_i)
    _friends, _followers = client.friends_and_followers(_raw_me.id.to_i) && client.friends_and_followers(_raw_me.id.to_i)

    tu = TwitterUser.new do |tu|
      tu.uid = _raw_me.id.to_i
      tu.screen_name = _raw_me.screen_name
      tu.user_info = _raw_me.slice(*SAVE_KEYS).to_json # TODO check the type of keys and values
    end

    if option[:all]
      tu.friends = _friends.map do |f|
        Friend.new({
                     from_id: nil,
                     uid: f.id,
                     screen_name: f.screen_name,
                     user_info: f.slice(*SAVE_KEYS).to_json})
      end

      tu.followers = _followers.map do |f|
        Follower.new({
                       from_id: nil,
                       uid: f.id,
                       screen_name: f.screen_name,
                       user_info: f.slice(*SAVE_KEYS).to_json})
      end
    end

    tu
  end

  def save_raw_twitter_data
    unless valid?
      logger.debug "[#{Time.zone.now}] #{self.class}#save_raw_twitter_data #{errors.full_messages}"
      return false
    end

    _friends, _followers = self.friends.map{|f| f }, self.followers.map{|f| f }
    self.friends = self.followers = []
    self.save

    begin
      self.transaction do
        _friends.map {|f| f.from_id = self.id }
        _friends.each_slice(100).each { |f| Friend.import(f) }

        _followers.map {|f| f.from_id = self.id }
        _followers.each_slice(100).each { |f| Follower.import(f) }
      end

      self.reload # for friends and followers
    rescue => e
      self.destroy
      false
    else
      true
    end
  end

  def self.oldest(user)
    user.kind_of?(Integer) ?
      order(created_at: :asc).find_by(uid: user.to_i) : order(created_at: :asc).find_by(screen_name: user.to_s)
  end

  def self.latest(user)
    user.kind_of?(Integer) ?
      order(created_at: :desc).find_by(uid: user.to_i) : order(created_at: :desc).find_by(screen_name: user.to_s)
  end

  DEFAULT_MINUTES = Rails.env.production? ? 30 : 5

  def recently_created?(minutes = DEFAULT_MINUTES)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end

  def recently_updated?(minutes = DEFAULT_MINUTES)
    Time.zone.now.to_i - updated_at.to_i < 60 * minutes
  end

  def oldest_me
    TwitterUser.oldest(uid.to_i)
  end

  def latest_me
    TwitterUser.latest(uid.to_i)
  end

  def mutual_friends
    ExTwitter.new.mutual_friends(self)
  end

  def removed_friends
    return [] if TwitterUser.where(screen_name: screen_name).limit(2).size < 2
    ExTwitter.new.removed_friends(oldest_me, latest_me)
  end

  def removed_followers
    return [] if TwitterUser.where(screen_name: screen_name).limit(2).size < 2
    ExTwitter.new.removed_followers(oldest_me, latest_me)
  end

  def users_replying(client)
    client.users_replying(self.screen_name)
  end

  def users_replied(client)
    client.users_replied(self.screen_name)
  end
end
