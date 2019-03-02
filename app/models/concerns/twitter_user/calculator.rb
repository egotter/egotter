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
    UnfriendsBuilder.new(self).unfriends
  end

  def calc_unfollower_uids
    UnfriendsBuilder.new(self).unfollowers
  end
end
