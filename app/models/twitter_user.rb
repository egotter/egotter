# == Schema Information
#
# Table name: twitter_users
#
#  id           :integer          not null, primary key
#  uid          :string(191)      not null
#  screen_name  :string(191)      not null
#  user_info    :text(65535)      not null
#  search_count :integer          default(0), not null
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
  has_many :friends,        foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :followers,      foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :statuses,       foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :mentions,       foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :search_results, foreign_key: :from_id, dependent: :destroy, validate: false
  has_many :favorites,      foreign_key: :from_id, dependent: :destroy, validate: false

  attr_accessor :client, :login_user, :egotter_context, :without_friends

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
    profile_link_color
    suspended
    verified
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

  def self.build_by_user(user, attrs = {})
    build_relation = attrs.has_key?(:build_relation) ? attrs.delete(:build_relation) : false
    tu = new(attrs) do |tu|
      tu.uid = user.id
      tu.screen_name = user.screen_name
      tu.user_info = user.slice(*PROFILE_SAVE_KEYS).to_json # TODO check the type of keys and values
    end
    tu.build_relations if build_relation
    tu
  end

  def self.build_by_client(client, user, attrs = {})
    build_by_user(client.user(user), attrs.merge(client: client))
  end

  def self.build(client, user, option = {})
    build_by_client(client, user, option)
  end

  def build_relations
    uid_i = uid.to_i
    search_query = "@#{screen_name}"

    if ego_surfing?
      candidates = [
        {method: :friends_advanced, args: [uid_i]},
        {method: :followers_advanced, args: [uid_i]},
        {method: :user_timeline, args: [uid_i]}, # for replying
        {method: :search, args: [search_query]}, # for replied
        {method: :home_timeline, args: [uid_i]},
        {method: :mentions_timeline, args: [uid_i]}, # for replied
        {method: :favorites, args: [uid_i]} # for favoriting
      ]
      if without_friends
        candidates = candidates.slice(2, candidates.size - 2)
        _statuses, _search_results, _, _mentions, _favorites = client.fetch_parallelly(candidates)
        _friends = _followers = []
      else
        _friends, _followers, _statuses, _search_results, _, _mentions, _favorites = client.fetch_parallelly(candidates)
      end
    else
      candidates = [
        {method: :friends_advanced, args: [uid_i]},
        {method: :followers_advanced, args: [uid_i]},
        {method: :user_timeline, args: [uid_i]},
        {method: :search, args: [search_query]},
        {method: :favorites, args: [uid_i]}
      ]
      if without_friends
        candidates = candidates.slice(2, candidates.size - 2)
        _statuses, _search_results, _favorites = client.fetch_parallelly(candidates)
        _friends = _followers = []
      else
        _friends, _followers, _statuses, _search_results, _favorites = client.fetch_parallelly(candidates)
      end
      _mentions = []
    end

    # Not using uniq for mentions, search_results and favorites intentionally

    client.fetch_parallelly([
                              {method: :replying, args: [uid_i]}
                            ])

    _friends.each do |f|
      friends.build(uid: f.id,
                       screen_name: f.screen_name,
                       user_info: f.slice(*PROFILE_SAVE_KEYS).to_json)
    end

    _followers.each do |f|
      followers.build(uid: f.id,
                         screen_name: f.screen_name,
                         user_info: f.slice(*PROFILE_SAVE_KEYS).to_json)
    end

    _statuses.each do |s|
      statuses.build(uid: uid,
                        screen_name: screen_name,
                        status_info: s.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end

    _mentions.each do |m|
      mentions.build(uid: m.user.id,
                        screen_name: m.user.screen_name,
                        status_info: m.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end

    _search_results.each do |sr|
      search_results.build(uid: sr.user.id,
                              screen_name: sr.user.screen_name,
                              status_info: sr.slice(*Status::STATUS_SAVE_KEYS).to_json,
                              query: search_query)
    end

    _favorites.each do |f|
      favorites.build(uid: f.user.id,
                         screen_name: f.user.screen_name,
                         status_info: f.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end

    true
  end

  def save_with_bulk_insert(validate = true)
    if validate && invalid?
      logger.debug "[#{Time.zone.now}] #{self.class}#save_raw_twitter_data #{errors.full_messages}"
      return false
    end

    _friends, _followers, _statuses, _mentions, _search_results, _favorites =
      friends.to_a.dup, followers.to_a.dup,
        statuses.to_a.dup, mentions.to_a.dup, search_results.to_a.dup, favorites.to_a.dup
    self.friends = self.followers = self.statuses = self.mentions = self.search_results = self.favorites = []
    save(validate: false)

    begin
      log_level = Rails.logger.level; Rails.logger.level = Logger::WARN

      unless without_friends
        self.transaction do
          _friends.map {|f| f.from_id = self.id }
          _friends.each_slice(100).each { |f| Friend.import(f, validate: false) }
        end
      end

      unless without_friends
        self.transaction do
          _followers.map {|f| f.from_id = self.id }
          _followers.each_slice(100).each { |f| Follower.import(f, validate: false) }
        end
      end

      self.transaction do
        _statuses.map {|s| s.from_id = self.id }
        _statuses.each_slice(100).each { |s| Status.import(s, validate: false) }
      end

      self.transaction do
        _mentions.map {|m| m.from_id = self.id }
        _mentions.each_slice(100).each { |m| Mention.import(m, validate: false) }
      end

      self.transaction do
        _search_results.map {|sr| sr.from_id = self.id }
        _search_results.each_slice(100).each { |sr| SearchResult.import(sr, validate: false) }
      end

      self.transaction do
        _favorites.map {|f| f.from_id = self.id }
        _favorites.each_slice(100).each { |f| Favorite.import(f, validate: false) }
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

  DEFAULT_SECONDS = Rails.configuration.x.constants['twitter_user_recently_created_threshold']

  def recently_created?(seconds = DEFAULT_SECONDS)
    Time.zone.now.to_i - created_at.to_i < seconds
  end

  def recently_updated?(seconds = DEFAULT_SECONDS)
    Time.zone.now.to_i - updated_at.to_i < seconds
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

  def replying(options = {})
    begin
      client.replying(__uid_i, options.merge(tweets: statuses)).map { |u| u.uid = u.id; u }
    rescue => e
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
      []
    end
  end

  def replied(options = {})
    if ego_surfing? && mentions.any?
      result = mentions.map { |m| m.user }.map { |u| u.uid = u.id; u }
      (options.has_key?(:uniq) && !options[:uniq]) ? result : result.uniq { |u| u.id.to_i }
    else
      ExTwitter.new.select_replied_from_search(search_results, options).map { |u| u.uid = u.id; u }
    end
  end

  def favoriting(options = {})
    client.favoriting(__uid_i, options.merge(favorites: favorites)).map { |u| u.uid = u.id; u }
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
    min = options.has_key?(:min) ? options.delete(:min) : 1
    client.close_friends(__uid_i, options.merge(
      min: min,
      replying: replying(options.merge(uniq: false)),
      replied: replied(uniq: false),
      favoriting: favoriting(options.merge(uniq: false)))
    ).map { |u| u.uid = u.id; u }
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

  def close_friends_graph(options = {})
    items = close_friends(options.merge(min: 0))
    items_size = items.size
    good = percentile_index(items, 0.10) + 1
    not_so_bad = percentile_index(items, 0.50) + 1
    so_so = percentile_index(items, 1.0) + 1
    [
      {name: I18n.t('legend.close_friends'), y: (good.to_f / items_size * 100), drilldown: 'good', sliced: true, selected: true},
      {name: I18n.t('legend.friends'), y: ((not_so_bad - good).to_f / items_size * 100), drilldown: 'not_so_bad'},
      {name: I18n.t('legend.acquaintance'), y: ((so_so - (good + not_so_bad)).to_f / items_size * 100), drilldown: 'so_so'}
    ]
    # drilldown_series = [
    #   {name: 'good', id: 'good', data: items.slice(0, good - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'not_so_bad', id: 'not_so_bad', data: items.slice(good, not_so_bad - 1).map { |i| [i.screen_name, i.score] }},
    #   {name: 'so_so', id: 'so_so', data: items.slice(not_so_bad, so_so - 1).map { |i| [i.screen_name, i.score] }},
    # ]
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

  def mutual_friends_rate
    friendship_size = friendship_uids.size
    return [0.0, 0.0, 0.0] if friendship_size == 0
    [
      mutual_friends.size.to_f / friendship_size * 100,
      one_sided_following.size.to_f / friendship_size * 100,
      one_sided_followers.size.to_f / friendship_size * 100
    ]
  end

  def mutual_friends_graph
    rates = mutual_friends_rate
    sliced = rates[0] < 25
    [
      {name: I18n.t('legend.mutual_friends'), y: rates[0], sliced: sliced, selected: sliced},
      {name: I18n.t('legend.one_sided_following'), y: rates[1]},
      {name: I18n.t('legend.one_sided_followers'), y: rates[2]}
    ]
  end

  def common_friends_graph(other)
    friends_size = friends.size
    common_friends_size = common_friends(other).size
    [
      {name: I18n.t('legend.common_friends'), y: (common_friends_size.to_f / friends_size * 100)},
      {name: I18n.t('legend.others'), y: ((friends_size - common_friends_size).to_f / friends_size * 100)}
    ]
  end

  def common_followers_graph(other)
    followers_size = followers.size
    common_followers_size = common_followers(other).size
    [
      {name: I18n.t('legend.common_followers'), y: (common_followers_size.to_f / followers_size * 100)},
      {name: I18n.t('legend.others'), y: ((followers_size - common_followers_size).to_f / followers_size * 100)}
    ]
  end

  def usage_stats_graph
    client.usage_stats(__uid_i, tweets: statuses)
  end

  def clusters_belong_to_graph
    clusters_belong_to.to_a.slice(0, 10).map { |word, count| {name: word, y: count} }
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
