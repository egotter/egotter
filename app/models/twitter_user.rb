# == Schema Information
#
# Table name: twitter_users
#
#  id           :integer          not null, primary key
#  uid          :string(255)      not null
#  screen_name  :string(255)      not null
#  user_info    :text(65535)      not null
#  search_count :integer          default(1), not null
#  update_count :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_screen_name  (screen_name)
#  index_twitter_users_on_uid          (uid)
#

class TwitterUser < ActiveRecord::Base
  has_many :friends, foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :followers, foreign_key: :from_id, dependent: :destroy, validate: false

  attr_accessor :client, :login_user, :egotter_context

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
    profile_image_url_https
    profile_banner_url
    suspended
  )

  delegate *PROFILE_SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :user_info_mash

  def user_info_mash
    return @user_info_mash if @user_info_mash.present?
    if user_info.present?
      @user_info_mash = Hashie::Mash.new(JSON.parse(user_info))
    else
      Hashie::Mash.new(JSON.parse('{"friends_count": -1, "followers_count": -1}'))
    end
  end

  include Concerns::TwitterUser::Validation

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

  def fetch_user?
    raise 'must set client' if client.nil?
    if self.uid.present? && self.uid.to_i != 0
      client.user?(uid.to_i)
    elsif self.screen_name.present?
      client.user?(self.screen_name.to_s)
    else
      raise self.inspect
    end
  end

  def fetch_user
    raise 'must set client' if client.nil?
    user =
      if self.uid.present? && self.uid.to_i != 0
        client.user(uid.to_i) && client.user(uid.to_i) # call 2 times to use cache
      elsif self.screen_name.present?
        client.user(self.screen_name.to_s) && client.user(self.screen_name.to_s)
      else
        raise self.inspect
      end
    self.uid = user.id.to_i
    self.screen_name = user.screen_name
    self.user_info = user.slice(*PROFILE_SAVE_KEYS).to_json # TODO check the type of keys and values
    self
  end

  def self.build(client, user, option = {})
    option[:all] = true unless option.has_key?(:all)

    # call 2 times to use cache
    _raw_me = client.user(user) && client.user(user)

    tu = TwitterUser.new do |tu|
      tu.uid = _raw_me.id.to_i
      tu.screen_name = _raw_me.screen_name
      tu.user_info = _raw_me.slice(*PROFILE_SAVE_KEYS).to_json # TODO check the type of keys and values
    end
    tu.client = client
    tu.login_user = option.has_key?(:login_user) ? option[:login_user] : nil
    tu.egotter_context = option.has_key?(:egotter_context) ? option[:egotter_context] : nil

    if option[:all]
      _friends, _followers =
        client.friends_and_followers_advanced(_raw_me.id.to_i) &&
          client.friends_and_followers_advanced(_raw_me.id.to_i)

      tu.friends = _friends.map do |f|
        Friend.new({
                     from_id: nil,
                     uid: f.id,
                     screen_name: f.screen_name,
                     user_info: f.slice(*PROFILE_SAVE_KEYS).to_json}) # It might be better to call to_hash
      end

      tu.followers = _followers.map do |f|
        Follower.new({
                       from_id: nil,
                       uid: f.id,
                       screen_name: f.screen_name,
                       user_info: f.slice(*PROFILE_SAVE_KEYS).to_json}) # It might be better to call to_hash
      end
    end

    tu
  end

  def save_with_bulk_insert(validate = true)
    if validate && invalid?
      logger.debug "[#{Time.zone.now}] #{self.class}#save_raw_twitter_data #{errors.full_messages}"
      return false
    end

    _friends, _followers = self.friends.to_a.dup, self.followers.to_a.dup
    self.friends = self.followers = []
    self.save(validate: false)

    begin
      log_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      self.transaction do
        _friends.map {|f| f.from_id = self.id }
        _friends.each_slice(100).each { |f| Friend.import(f, validate: false) }

        _followers.map {|f| f.from_id = self.id }
        _followers.each_slice(100).each { |f| Follower.import(f, validate: false) }
      end
      Rails.logger.level = log_level

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

  def replying
    self.client.replying(self.uid.to_i)
  end

  def replied
    self.client.replied(self.screen_name)
  end

  def inactive_friends
    # friends relation is not used because of using status which is not saved to db
    self.client.inactive_friends(self.uid.to_i)
  end

  def inactive_followers
    # followers relation is not used because of using status which is not saved to db
    self.client.inactive_followers(self.uid.to_i)
  end

  def clusters_belong_to
    text = self.client.user_timeline(self.uid.to_i).map{|s| s.text }.join(' ')
    ExTwitter.new.clusters_belong_to(text)
  end

  def search_and_touch
    update(search_count: search_count + 1)
  end

  def update_and_touch
    update(update_count: update_count + 1)
  end

  def eql?(other)
    self.uid.to_i == other.uid.to_i
  end

  def hash
    self.uid.to_i.hash
  end
end
