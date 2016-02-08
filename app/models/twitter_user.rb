# == Schema Information
#
# Table name: twitter_users
#
#  id           :integer          not null, primary key
#  uid          :string(191)      not null
#  screen_name  :string(191)      not null
#  user_info    :text(65535)      not null
#  search_count :integer          default(1), not null
#  update_count :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at   (created_at)
#  index_twitter_users_on_screen_name  (screen_name)
#  index_twitter_users_on_uid          (uid)
#

class TwitterUser < ActiveRecord::Base
  has_many :friends,   foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :followers, foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :statuses,  foreign_key: :from_id, dependent: :destroy, validate: false

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
    status
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

  def has_key?(key)
    user_info_mash.has_key?(key)
  end

  include Concerns::TwitterUser::Validation

  def __uid_i
    uid.to_i
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

  def friendship_uids
    (friend_uids + follower_uids).uniq
  end

  def diff(tu)
    raise "uid is different(#{self.uid},#{tu.uid})" if __uid_i != tu.__uid_i
    diffs = []
    diffs << "friends_count(#{self.friends_count},#{tu.friends_count})" if self.friends_count != tu.friends_count
    diffs << "followers_count(#{self.followers_count},#{tu.followers_count})" if self.followers_count != tu.followers_count
    diffs << "friends(#{self.friend_uids.size},#{tu.friend_uids.size})" if self.friend_uids != tu.friend_uids
    diffs << "followers(#{self.follower_uids.size},#{tu.follower_uids.size})" if self.follower_uids != tu.follower_uids
    diffs
  end

  def fetch_user?
    raise 'must set client' if client.nil?
    if self.uid.present? && __uid_i != 0
      client.user?(__uid_i)
    elsif self.screen_name.present?
      client.user?(self.screen_name.to_s)
    else
      raise self.inspect
    end
  end

  def fetch_user
    raise 'must set client' if client.nil?
    user =
      if self.uid.present? && __uid_i != 0
        client.user(__uid_i) && client.user(__uid_i) # call 2 times to use cache
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

  def self.build(client, _user, option = {})
    option[:all] = true unless option.has_key?(:all)

    user = client.user(_user) && client.user(_user, cache: :force)
    uid_i = user.id.to_i

    tu = TwitterUser.new do |tu|
      tu.uid = uid_i
      tu.screen_name = user.screen_name
      tu.user_info = user.slice(*PROFILE_SAVE_KEYS).to_json # TODO check the type of keys and values
    end
    tu.client = client
    tu.login_user = option.has_key?(:login_user) ? option[:login_user] : nil
    tu.egotter_context = option.has_key?(:egotter_context) ? option[:egotter_context] : nil

    if option[:all]
      client.fetch_parallelly([
                                {method: :friends_advanced, args: [uid_i]},
                                {method: :followers_advanced, args: [uid_i]},
                                {method: :user_timeline, args: [uid_i]},
                                {method: :search, args: [tu.screen_name.to_s]}])

      if tu.login_user.present? && tu.egotter_context == 'search' &&
        tu.login_user.uid.to_i == uid_i && tu.client.uid.to_i == uid_i
        client.fetch_parallelly([
                                  {method: :home_timeline, args: [uid_i]},
                                  {method: :mentions_timeline, args: [uid_i]}])
      end

      # TODO Maybe this method call is time loss as it parses json.
      _friends = client.friends_advanced(uid_i, cache: :force)
      _followers = client.followers_advanced(uid_i, cache: :force)
      _statuses = client.user_timeline(uid_i, cache: :force)

      tu.friends = _friends.map do |f|
        Friend.new({
                     from_id: nil,
                     uid: f.id,
                     screen_name: f.screen_name,
                     user_info: f.slice(*PROFILE_SAVE_KEYS).to_json})
      end

      tu.followers = _followers.map do |f|
        Follower.new({
                       from_id: nil,
                       uid: f.id,
                       screen_name: f.screen_name,
                       user_info: f.slice(*PROFILE_SAVE_KEYS).to_json})
      end

      tu.statuses = _statuses.map do |s|
        Status.new({
                       from_id: nil,
                       uid: tu.uid,
                       screen_name: tu.screen_name,
                       status_info: s.slice(*Status::STATUS_SAVE_KEYS).to_json})
      end
    end

    tu
  end

  def save_with_bulk_insert(validate = true)
    if validate && invalid?
      logger.debug "[#{Time.zone.now}] #{self.class}#save_raw_twitter_data #{errors.full_messages}"
      return false
    end

    _friends, _followers, _statuses = self.friends.to_a.dup, self.followers.to_a.dup, self.statuses.to_a.dup
    self.friends = self.followers = self.statuses = []
    self.save(validate: false)

    begin
      log_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      self.transaction do
        _friends.map {|f| f.from_id = self.id }
        _friends.each_slice(100).each { |f| Friend.import(f, validate: false) }

        _followers.map {|f| f.from_id = self.id }
        _followers.each_slice(100).each { |f| Follower.import(f, validate: false) }

        _statuses.map {|s| s.from_id = self.id }
        _statuses.each_slice(100).each { |s| Status.import(s, validate: false) }
      end
      Rails.logger.level = log_level

      self.reload # for friends, followers and statuses
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

  DEFAULT_MINUTES = 30

  def recently_created?(minutes = DEFAULT_MINUTES)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end

  def recently_updated?(minutes = DEFAULT_MINUTES)
    Time.zone.now.to_i - updated_at.to_i < 60 * minutes
  end

  def oldest_me
    TwitterUser.oldest(__uid_i)
  end

  def latest_me
    TwitterUser.latest(__uid_i)
  end

  def one_sided_following
    ExTwitter.new.one_sided_following(self)
  end

  def one_sided_followers
    ExTwitter.new.one_sided_followers(self)
  end

  def mutual_friends
    ExTwitter.new.mutual_friends(self)
  end

  def common_friends(other)
    return [] if other.blank?
    ExTwitter.new.common_friends(self, other)
  end

  def common_followers(other)
    return [] if other.blank?
    ExTwitter.new.common_followers(self, other)
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
    screen_names = ExTwitter.new.select_screen_names_replied(statuses)
    _users = client.users(screen_names) && client.users(screen_names)
    _users.map { |u| u.uid = u.id; u }
  end

  def replied
    _replied =
      begin
        client.replied(__uid_i) && client.replied(__uid_i)
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
        []
      end
    _replied.map { |u| u.uid = u.id; u }
  end

  def favoriting
    _favoriting =
      begin
        client.favoriting(__uid_i) && client.favoriting(__uid_i)
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
        []
      end
    _favoriting.map { |u| u.uid = u.id; u }
  end

  def inactive_friends
    ExTwitter.new.select_inactive_users(friends, authorized: ego_surfing?)
  end

  def inactive_followers
    ExTwitter.new.select_inactive_users(followers, authorized: ego_surfing?)
  end

  def clusters_belong_to
    text = statuses.map{|s| s.text }.join(' ')
    ExTwitter.new.clusters_belong_to(text)
  end

  def close_friends(options = {})
    _close_friends =
      begin
        client.close_friends(__uid_i, options) && client.close_friends(__uid_i, options)
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
        []
      end
    _close_friends.map { |u| u.uid = u.id; u }
  end

  def inactive_friends_graph
    inactive_friends_size = inactive_friends.size
    friends_size = friends.size
    [
      {name: I18n.t('legend.inactive_friends'), y: (inactive_friends_size.to_f / friends_size * 100)},
      {name: I18n.t('legend.not_inactive_friends'), y: ((friends_size - inactive_friends_size).to_f / friends_size * 100)}
    ]
  end

  def inactive_followers_graph
    inactive_followers_size = inactive_followers.size
    followers_size = followers.size
    [
      {name: I18n.t('legend.inactive_followers'), y: (inactive_followers_size.to_f / followers_size * 100)},
      {name: I18n.t('legend.not_inactive_followers'), y: ((followers_size - inactive_followers_size).to_f / followers_size * 100)}
    ]
  end

  def replying_graph
    friends_size = friends.size
    replying_size = replying.size
    [
      {name: I18n.t('legend.replying'), y: (replying_size.to_f / friends_size * 100)},
      {name: I18n.t('legend.others'), y: ((friends_size - replying_size).to_f / friends_size * 100)}
    ]
  end

  def replied_graph
    followers_size = followers.size
    replied_size = replied.size
    [
      {name: I18n.t('legend.replying'), y: (replied_size.to_f / followers_size * 100)},
      {name: I18n.t('legend.others'), y: ((followers_size - replied_size).to_f / followers_size * 100)}
    ]
  end

  def favoriting_graph
    friends_size = friends.size
    favoriting_size = favoriting.size
    [
      {name: I18n.t('legend.favoriting'), y: (favoriting_size.to_f / friends_size * 100)},
      {name: I18n.t('legend.others'), y: ((friends_size - favoriting_size).to_f / friends_size * 100)}
    ]
  end

  def close_friends_graph
    items = close_friends(min: 0, max: 100)
    items_size = items.size
    good = (percentile_index(items, 0.10) + 1)
    not_so_bad = (percentile_index(items, 0.50) + 1) - good
    so_so = items.size - (good + not_so_bad)
    [
      {name: I18n.t('legend.close_friends'), y: (good.to_f / items_size * 100), sliced: true, selected: true},
      {name: I18n.t('legend.friends'), y: (not_so_bad.to_f / items_size * 100)},
      {name: I18n.t('legend.acquaintance'), y: (so_so.to_f / items_size * 100)}
    ]
  end

  def one_sided_following_graph
    friends_size = friends.size
    one_sided_size = one_sided_following.size
    [
      {name: I18n.t('legend.one_sided_following'), y: (one_sided_size.to_f / friends_size * 100)},
      {name: I18n.t('legend.others'), y: ((friends_size - one_sided_size).to_f / friends_size * 100)}
    ]
  end

  def one_sided_followers_graph
    followers_size = followers.size
    one_sided_size = one_sided_followers.size
    [
      {name: I18n.t('legend.one_sided_followers'), y: (one_sided_size.to_f / followers_size * 100)},
      {name: I18n.t('legend.others'), y: ((followers_size - one_sided_size).to_f / followers_size * 100)}
    ]
  end

  def mutual_friends_graph
    friendship_size = friendship_uids.size
    [
      {name: I18n.t('legend.mutual_friends'), y: (mutual_friends.size.to_f / friendship_size * 100), sliced: true, selected: true},
      {name: I18n.t('legend.one_sided_following'), y: (one_sided_following.size.to_f / friendship_size * 100)},
      {name: I18n.t('legend.one_sided_followers'), y: (one_sided_followers.size.to_f / friendship_size * 100)}
    ]
  end

  def usage_stats_graph
    client.usage_stats(__uid_i)
  end

  def percentile_index(ary, percentile = 0.0)
    ((ary.length * percentile).ceil) - 1
  end

  def usage_stats(options = {})
    client.usage_stats(__uid_i, options)
  end

  def search_and_touch
    update(search_count: search_count + 1)
  end

  def update_and_touch
    update(update_count: update_count + 1)
  end

  def eql?(other)
    __uid_i == other.__uid_i
  end

  def hash
    __uid_i.hash
  end
end
