require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def calc_removing_uids(uid)
      with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
        next if newer.nil? || older.nil? || newer.friends_size == 0
        older.new_removing_uids(newer)
      end.compact.flatten.reverse
    end

    def calc_removed_uids(uid)
      TwitterUser.with_friends.where(uid: uid).order(created_at: :asc).each_cons(2).map do |older, newer|
        next if newer.nil? || older.nil? || newer.followers_size == 0
        older.new_removed_uids(newer)
      end.compact.flatten.reverse
    end

    def select_inactive_users(users)
      users.select { |user| _inactive_user?(user) }
    end

    def _inactive_user?(user)
      user&.status&.created_at && Time.parse(user.status.created_at) < 2.weeks.ago
    rescue => e
      logger.warn "#{__method__}: #{e.class} #{e.message} [#{user&.status&.created_at}] #{user.uid} #{user.screen_name}"
      false
    end
  end

  def calc_one_sided_friend_uids
    friend_uids - follower_uids
  end

  def one_sided_friend_uids
    one_sided_friendships.pluck(:friend_uid)
  end

  def calc_one_sided_follower_uids
    follower_uids - friend_uids
  end

  def one_sided_follower_uids
    one_sided_followerships.pluck(:follower_uid)
  end

  def calc_mutual_friend_uids
    friend_uids & follower_uids
  end

  def mutual_friend_uids
    mutual_friendships.pluck(:friend_uid)
  end

  def common_friend_uids(other)
    friend_uids & other.friend_uids
  end

  def common_friends(other)
    uids = common_friend_uids(other)
    uids.empty? ? [] : friends.where(uid: uids)
  end

  def common_follower_uids(other)
    follower_uids & other.follower_uids
  end

  def common_followers(other)
    uids = common_follower_uids(other)
    uids.empty? ? [] : followers.where(uid: uids)
  end

  def conversations(other)
    statuses1 = statuses.select { |status| status.mention_to?(other.mention_name) }
    statuses2 = other.statuses.select { |status| status.mention_to?(mention_name) }
    (statuses1 + statuses2).sort_by { |status| -status.tweeted_at.to_i }
  end

  def new_removing_uids(newer)
    friend_uids - newer.friend_uids
  end

  def new_removing
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return friends.none if newer.nil? || older.nil? || newer.friends_size == 0
    uids = older.new_removing_uids(newer)
    uids.empty? ? friends.none : older.friends.where(uid: uids)
  end

  def removing_uids
    unfriendships.pluck(:friend_uid)
  end

  def removing
    unfriends
  end

  def new_removed_uids(newer)
    follower_uids - newer.follower_uids
  end

  def new_removed
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return followers.none if newer.nil? || older.nil? || newer.followers_size == 0
    uids = older.new_removed_uids(newer)
    uids.empty? ? followers.none : older.followers.where(uid: uids)
  end

  def removed_uids
    unfollowerships.pluck(:follower_uid)
  end

  def removed
    unfollowers
  end

  def blocking_or_blocked_uids
    removing_uids & removed_uids
  end

  def blocking_or_blocked
    uids = blocking_or_blocked_uids
    uids.empty? ? removing.none : removing.where(uid: uids)
  end

  def new_friend_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil?
    return newer.friend_uids.take(8) if older.nil? || older.friends_size == 0
    uids = newer.friend_uids - older.friend_uids
    uids.empty? ? newer.friend_uids.take(8) : uids
  end

  def new_friends
    uids = new_friend_uids
    return friends.none if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def new_follower_uids
    newer, older = TwitterUser.with_friends.where(uid: uid).order(created_at: :desc).take(2)
    return [] if newer.nil?
    return newer.follower_uids.take(8) if older.nil? || older.followers_size == 0
    uids = newer.follower_uids - older.follower_uids
    uids.empty? ? newer.follower_uids.take(8) : uids
  end

  def new_followers
    uids = new_follower_uids
    return followers.none if uids.empty?
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def replying_uids(uniq: true)
    uids = UsageStat.find_by(uid: uid)&.mentions&.keys&.map(&:to_s)&.map(&:to_i) || []
    uniq ? uids.uniq : uids
  end

  def replying(uniq: true)
    uids = replying_uids(uniq: uniq)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def reply_tweets(login_user: nil)
    if login_user&.uid&.to_i == uid.to_i
      mentions
    elsif search_results.any?
      search_results.select { |status| status.mention_to?(mention_name) }
    else
      []
    end
  end

  def replied_uids(uniq: true, login_user: nil)
    uids = reply_tweets(login_user: login_user).map { |tweet| tweet.user&.id }.compact
    uniq ? uids.uniq : uids
  end

  def replied(uniq: true, login_user: nil)
    users = reply_tweets(login_user: login_user).map(&:user).compact
    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def replying_and_replied_uids(uniq: true, login_user: nil)
    replying_uids(uniq: uniq) & replied_uids(uniq: uniq, login_user: login_user)
  end

  def replying_and_replied(uniq: true, login_user: nil)
    uids = replying_and_replied_uids(uniq: uniq, login_user: login_user)
    users = (replying(uniq: uniq) + replied(uniq: uniq, login_user: login_user)).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def calc_favorite_friend_uids(uniq: true)
    uids = favorites.map { |fav| fav&.user&.id }.compact
    if uniq
      uids.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.map(&:first)
    else
      uids
    end
  end

  def favorite_friend_uids
    favorite_friendships.pluck(:friend_uid)
  end

  def favoriting_uids(uniq: true, min: 0)
    logger.warn "DUPLICATED #{__method__}"
    favorite_friend_uids
  end

  def favoriting(uniq: true, min: 0)
    logger.warn "DUPLICATED #{__method__}"
    uids = favoriting_uids(uniq: uniq, min: min)
    users = favorites.map(&:user).index_by(&:id)
    users = uids.map { |uid| users[uid] }
    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def calc_close_friend_uids
    login_user = mentions.any? ? Hashie::Mash.new(uid: uid) : nil
    uids = replying_uids(uniq: false) + replied_uids(uniq: false, login_user: login_user) + calc_favorite_friend_uids(uniq: false)
    uids.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.take(50).map(&:first)
  end

  def close_friend_uids
    # TODO remove later
    if close_friendships.any?
      close_friendships.pluck(:friend_uid)
    else
      calc_close_friend_uids
    end
  end

  def calc_inactive_friend_uids
    friends.select { |friend| self.class._inactive_user?(friend) }.map(&:uid)
  end

  def inactive_friend_uids
    inactive_friendships.pluck(:friend_uid)
  end

  def calc_inactive_follower_uids
    followers.select { |follower| self.class._inactive_user?(follower) }.map(&:uid)
  end

  def inactive_follower_uids
    inactive_followerships.pluck(:follower_uid)
  end

  def calc_inactive_mutual_friend_uids
    mutual_friends.select { |friend| self.class._inactive_user?(friend) }.map(&:uid)
  end

  def inactive_mutual_friend_uids
    inactive_mutual_friendships.pluck(:friend_uid)
  end
end
