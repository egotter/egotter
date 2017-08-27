require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def select_inactive_users(users)
      users.select { |user| inactive_user?(user) }
    end

    def inactive_user?(user)
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

  def one_sided_friends_rate
    (one_sided_friendships.size.to_f / friendships.size) rescue 0.0
  end

  def calc_one_sided_follower_uids
    follower_uids - friend_uids
  end

  def one_sided_follower_uids
    one_sided_followerships.pluck(:follower_uid)
  end

  def one_sided_followers_rate
    (one_sided_followerships.size.to_f / followerships.size) rescue 0.0
  end

  def follow_back_rate
    (mutual_friendships.size.to_f / followerships.size) rescue 0.0
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

  def calc_close_friend_uids
    login_user = mentions.any? ? Hashie::Mash.new(uid: uid) : nil
    uids = replying_uids(uniq: false) + replied_uids(uniq: false, login_user: login_user) + calc_favorite_friend_uids(uniq: false)
    uids.each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.sort_by { |_, v| -v }.take(50).map(&:first)
  end

  def close_friend_uids
    close_friendships.pluck(:friend_uid)
  end

  def calc_inactive_friend_uids
    friends.select { |friend| self.class.inactive_user?(friend) }.map(&:uid)
  end

  def inactive_friend_uids
    inactive_friendships.pluck(:friend_uid)
  end

  def calc_inactive_follower_uids
    followers.select { |follower| self.class.inactive_user?(follower) }.map(&:uid)
  end

  def inactive_follower_uids
    inactive_followerships.pluck(:follower_uid)
  end

  def calc_inactive_mutual_friend_uids
    mutual_friends.select { |friend| self.class.inactive_user?(friend) }.map(&:uid)
  end

  def inactive_mutual_friend_uids
    inactive_mutual_friendships.pluck(:friend_uid)
  end
end
