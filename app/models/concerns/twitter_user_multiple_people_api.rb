require 'active_support/concern'

module TwitterUserMultiplePeopleApi
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
    uids = common_mutual_friend_uids(other)
    TwitterDB::Proxy.new(uids).limit(uids.size).to_a
  end
end
