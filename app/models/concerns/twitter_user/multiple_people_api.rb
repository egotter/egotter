require 'active_support/concern'

module Concerns::TwitterUser::MultiplePeopleApi
  extend ActiveSupport::Concern

  def common_friend_uids(other)
    friend_uids & other.friend_uids
  end

  def common_friends(other)
    friends.select { |f| other.friend_uids.include?(f.uid) }
  end

  def common_follower_uids(other)
    follower_uids & other.follower_uids
  end

  def common_followers(other)
    followers.select { |f| other.follower_uids.include?(f.uid) }
  end

  def common_mutual_friend_uids(other)
    mutual_friend_uids & other.mutual_friend_uids
  end

  def common_mutual_friends(other)
    TwitterDB::User.where_and_order_by_field(uids: common_mutual_friend_uids(other))
  end
end
