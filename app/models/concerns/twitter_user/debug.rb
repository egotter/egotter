require 'active_support/concern'

module Concerns::TwitterUser::Debug
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def debug_print
    Rails.logger.silence do
      user = TwitterDB::User.find_by(uid: uid)

      puts 'friends'
      puts [friends.size, friendships.size, friends_size, friends_count, user.friends.size, user.friendships.size, user.friends_size, user.friends_count].inspect
      puts [followers.size, followerships.size, followers_size, followers_count, user.followers.size, user.followerships.size, user.followers_size, user.followers_count].inspect

      puts 'statuses, mentions, search_results, favorites'
      puts [statuses.size, mentions.size, search_results.size, favorites.size].inspect

      puts 'unfriends'
      puts [unfriends.size, unfriendships.size, TwitterUser.calc_removing_uids(uid).size].inspect
      puts [unfollowers.size, unfollowerships.size, TwitterUser.calc_removed_uids(uid).size].inspect

      puts 'one_sided_friends'
      puts [one_sided_friends.size, one_sided_friendships.size, calc_one_sided_friend_uids.size].inspect
      puts [one_sided_followers.size, one_sided_followerships.size, calc_one_sided_follower_uids.size].inspect
      puts [mutual_friends.size, mutual_friendships.size, calc_mutual_friend_uids.size].inspect

      puts 'inactive_friends'
      puts [inactive_friends.size, inactive_friendships.size, calc_inactive_friend_uids.size].inspect
      puts [inactive_followers.size, inactive_followerships.size, calc_inactive_follower_uids.size].inspect
      puts [inactive_mutual_friends.size, inactive_mutual_friendships.size, calc_inactive_mutual_friend_uids.size].inspect

      puts 'replying'
      puts [replying_uids.size, replying.size].inspect

      puts 'replied'
      puts [replied_uids.size, replied.size].inspect

      puts 'favoriting'
      puts [favoriting_uids.size, favoriting.size].inspect
    end
  end
end
