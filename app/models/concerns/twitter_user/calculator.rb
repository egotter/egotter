require 'active_support/concern'

module Concerns::TwitterUser::Calculator
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  def calc_one_sided_friend_uids
    friend_uids - follower_uids
  end

  def calc_one_sided_follower_uids
    follower_uids - friend_uids
  end

  def calc_mutual_friend_uids
    friend_uids & follower_uids
  end

  # private
  def calc_favorite_uids
    favorites.map { |fav| fav&.user&.id }.compact
  end

  # private
  def sort_by_count_desc(ids)
    ids.each_with_object(Hash.new(0)) { |id, memo| memo[id] += 1 }.sort_by { |_, v| -v }.map(&:first)
  end

  def calc_favorite_friend_uids(uniq: true)
    uids = calc_favorite_uids
    uniq ? sort_by_count_desc(uids) : uids
  end

  def calc_close_friend_uids
    login_user = mentions.any? ? Hashie::Mash.new(uid: uid) : nil
    uids = replying_uids(uniq: false) + replied_uids(uniq: false, login_user: login_user) + calc_favorite_friend_uids(uniq: false)
    sort_by_count_desc(uids).take(50)
  end

  def calc_inactive_friend_uids
    friends.select(&:inactive?).map(&:uid)
  end

  def calc_inactive_follower_uids
    followers.select(&:inactive?).map(&:uid)
  end

  def calc_inactive_mutual_friend_uids
    mutual_friends.select(&:inactive?).map(&:uid)
  end

  def calc_block_friend_uids
    calc_unfriend_uids & calc_unfollower_uids
  end

  def unfriendships
    logger.warn "DEPRECATE WARNING: unfriendships"
    calc_unfriend_uids
  end

  def calc_unfriend_uids
    TwitterUser.where('created_at <= ?', created_at).with_friends.where(uid: uid).select(:id, :friends_size).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      older.friend_uids - newer.friend_uids
    end.compact.flatten.reverse
  end

  def unfriendships_too_slow
    ids = TwitterUser.where('created_at <= ?', created_at).with_friends.where(uid: uid).order(created_at: :asc).pluck(:id)
    friendships = Friendship.where(from_id: ids).pluck(:from_id, :friend_uid)
    ids.each_cons(2).map do |older_id, newer_id|
      older = friendships.select { |f| f[0] == older_id }.map { |f| f[1] }
      newer = friendships.select { |f| f[0] == newer_id }.map { |f| f[1] }
      next if newer.empty?
      older - newer
    end.compact.flatten.reverse
  end

  def unfollowerships
    logger.warn "DEPRECATE WARNING: unfollowerships"
    calc_unfollower_uids
  end

  def calc_unfollower_uids
    TwitterUser.where('created_at <= ?', created_at).with_friends.where(uid: uid).select(:id, :followers_size).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      older.follower_uids - newer.follower_uids
    end.compact.flatten.reverse
  end
end
