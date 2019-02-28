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

  def calc_close_friend_uids(login_user:)
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

  def calc_unfriend_uids
    TwitterUser.where('created_at <= ?', created_at).with_friends.where(uid: uid).select(:id, :friends_size).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.friends_size == 0
      older.friend_uids - newer.friend_uids
    end.compact.flatten.reverse
  end

  def calc_unfollower_uids
    TwitterUser.where('created_at <= ?', created_at).with_friends.where(uid: uid).select(:id, :followers_size).order(created_at: :asc).each_cons(2).map do |older, newer|
      next if newer.nil? || older.nil? || newer.followers_size == 0
      older.follower_uids - newer.follower_uids
    end.compact.flatten.reverse
  end

  def calc_new_friend_uids
    older = TwitterUser.where('created_at < ?', created_at).with_friends.where(uid: uid).select(:id).order(created_at: :desc).limit(1).first
    older ? friend_uids - older.friend_uids : []
  end

  def calc_new_follower_uids
    older = TwitterUser.where('created_at < ?', created_at).with_friends.where(uid: uid).select(:id).order(created_at: :desc).limit(1).first
    older ? follower_uids - older.follower_uids : []
  end
end
