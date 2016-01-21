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

  TOO_MANY_FRIENDS = 5000

  validates :uid, presence: true, numericality: :only_integer
  validates :screen_name, presence: true, length: {maximum: 75}
  validates :user_info, presence: true
  validate :friends_or_followers_different?
  validate :friends_and_followers_zero?
  validate :friends_and_followers_too_many?
  validate :recently_created_record_exists?
  validate :same_record_exists?

  def friends_or_followers_different?
    if friends_count != friends.size || followers_count != followers.size
      errors[:base] << 'friends_count or followers_count is different from friends.size or followers.size'
      return true
    end

    false
  end

  def friends_and_followers_zero?
    if friends.size + followers.size == 0
      errors[:base] << 'sum of friends and followers is zero'
      return true
    end

    false
  end

  def friends_and_followers_too_many?
    if friends.size + followers.size  > TOO_MANY_FRIENDS
      errors[:base] << 'too many friends and followers'
      return true
    end

    false
  end

  def recently_created_record_exists?
    me = latest_me
    return false if me.blank?
    if me.recently_created? || me.recently_updated?
      errors[:base] << 'recently_created? or recently_updated? is true'
      return true
    end

    false
  end

  def same_record_exists?
    same_record?(latest_me)
  end

  def same_record?(tu)
    return false if tu.blank?
    raise "uid is different(#{self.uid},#{tu.uid})" if self.uid.to_i != tu.uid.to_i

    if tu.friends_count != self.friends_count || tu.followers_count != self.followers_count
      logger.debug "#{screen_name} friends_count or followers_count is different"
      return false
    end

    if tu.friend_uids != self.friend_uids || tu.follower_uids != self.follower_uids
      logger.debug "#{screen_name} friends or followers are different"
      return false
    end

    errors[:base] << "id:#{tu.id} is the same"
    true
  end

  # sorting to use eql? method
  def friend_uids
    if new_record?
      friends.map { |f| f.uid.to_i }.sort
    else
      friends.pluck(:uid).map { |uid| uid.to_i }.sort
    end
  end

  # sorting to use eql? method
  def follower_uids
    if new_record?
      followers.map { |f| f.uid.to_i }.sort
    else
      followers.pluck(:uid).map { |uid| uid.to_i }.sort
    end
  end

  def diff(tu)
    raise "uid is different(#{self.uid},#{tu.uid})" if self.uid.to_i != tu.uid.to_i
    diffs = []
    diffs << "friends_count(#{self.friends_count},#{tu.friends_count})" if self.friends_count != tu.friends_count
    diffs << "followers_count(#{self.followers_count},#{tu.followers_count})" if self.followers_count != tu.followers_count
    diffs << "friends(#{self.friend_uids.size},#{tu.friend_uids.size})" if self.friend_uids != tu.friend_uids
    diffs << "followers(#{self.follower_uids.size},#{tu.follower_uids.size})" if self.follower_uids != tu.follower_uids
    diffs
  end

  def self.build(client, uid, option = {})
    option = {all: true} if option.blank?

    # call 2 times to use cache
    _raw_me = client.user(uid.to_i) && client.user(uid.to_i)
    _friends, _followers =
      client.friends_and_followers_advanced(_raw_me.id.to_i) && client.friends_and_followers_advanced(_raw_me.id.to_i)

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

  def save_with_bulk_insert(validate = true)
    if validate && !valid?
      logger.debug "[#{Time.zone.now}] #{self.class}#save_raw_twitter_data #{errors.full_messages}"
      return false
    end

    _friends, _followers = self.friends.to_a.dup, self.followers.to_a.dup
    self.friends = self.followers = []
    self.save(validate: false)

    begin
      self.transaction do
        _friends.map {|f| f.from_id = self.id }
        _friends.each_slice(100).each { |f| Friend.import(f, validate: false) }

        _followers.map {|f| f.from_id = self.id }
        _followers.each_slice(100).each { |f| Follower.import(f, validate: false) }
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

  def only_following
    ExTwitter.new.only_following(self)
  end

  def only_followed
    ExTwitter.new.only_followed(self)
  end

  def mutual_friends
    ExTwitter.new.mutual_friends(self)
  end

  def friends_in_common(other)
    return [] if other.blank?
    ExTwitter.new.friends_in_common(self, other)
  end

  def followers_in_common(other)
    return [] if other.blank?
    ExTwitter.new.followers_in_common(self, other)
  end

  def removing
    return [] if TwitterUser.where(screen_name: screen_name).limit(2).size < 2
    ExTwitter.new.removing(oldest_me, latest_me)
  end

  def removed
    return [] if TwitterUser.where(screen_name: screen_name).limit(2).size < 2
    ExTwitter.new.removed(oldest_me, latest_me)
  end

  def replying(client)
    client.replying(self.uid.to_i)
  end

  def replied(client)
    client.replied(self.screen_name)
  end

  def clusters_belong_to(client)
    text = client.user_timeline(self.uid.to_i).map{|s| s.text }.join(' ')
    ExTwitter.new.clusters_belong_to(text)
  end

  def eql?(other)
    self.uid.to_i == other.uid.to_i
  end

  def hash
    self.uid.to_i.hash
  end
end
