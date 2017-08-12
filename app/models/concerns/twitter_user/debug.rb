require 'active_support/concern'

module Concerns::TwitterUser::Debug
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def consistent?(verbose: false)
    user = TwitterDB::User.find_by(uid: uid)

    friends_counts1 = [friends.size, friendships.size, friends_size, friends_count]
    friends_counts2 = [user.friends.size, user.friendships.size, user.friends_size, user.friends_count]

    followers_counts1 = [followers.size, followerships.size, followers_size, followers_count]
    followers_counts2 = [user.followers.size, user.followerships.size, user.followers_size, user.followers_count]

    if verbose
      (friends_counts1 + friends_counts2).uniq.one? && (followers_counts1 + followers_counts2).uniq.one?
    else
      ((friends_counts1 + friends_counts2).uniq.one? && (followers_counts1 + followers_counts2).uniq.one?) ||
        (friends_counts1.take(3) == [0, 0, 0] && friends_counts2.take(3) == [0, 0, -1] &&
          followers_counts1.take(3) == [0, 0, 0] && followers_counts2.take(3) == [0, 0, -1]) ||
        ((friends_counts1.take(3) + friends_counts2.take(3)).uniq.one? &&
          (followers_counts1.take(3) + followers_counts2.take(3)).uniq.one?)
    end
  end

  def need_repair?
    [friendships.size, friends_size].uniq.many? && [followerships.size, followers_size].uniq.many?
  end

  def debug_print_friends
    user = TwitterDB::User.find_by(uid: uid)
    delim = ' '

    puts([
           [friends.size, friendships.size, friends_size, friends_count].inspect,
           [user.friends.size, user.friendships.size, user.friends_size, user.friends_count].inspect,
           [followers.size, followerships.size, followers_size, followers_count].inspect,
           [user.followers.size, user.followerships.size, user.followers_size, user.followers_count].inspect
         ].join delim)
  end

  def debug_print(kind = nil)
    user = TwitterDB::User.find_by(uid: uid)
    delim = ' '

    puts
    puts %w(created_at updated_at).join delim
    puts [[created_at.to_s(:db), updated_at.to_s(:db)].inspect, [user.created_at.to_s(:db), user.updated_at.to_s(:db)].inspect].join delim
    puts

    puts %w(protected? one? latest? size).join delim
    puts [protected_account?, one?, latest?, size].inspect
    puts

    puts %w(friends friendships friends_size friends_count).join delim
    puts [[friends.size, friendships.size, friends_size, friends_count].inspect, [user.friends.size, user.friendships.size, user.friends_size, user.friends_count].inspect].join delim
    puts

    puts %w(followers followerships followers_size followers_count).join delim
    puts [[followers.size, followerships.size, followers_size, followers_count].inspect, [user.followers.size, user.followerships.size, user.followers_size, user.followers_count].inspect].join delim

    if kind == :all
      puts

      puts %w(statuses mentions search_results favorites).join delim
      puts [statuses.size, mentions.size, search_results.size, favorites.size].inspect
      puts

      puts %w(unfriends unfriendships calc_removing_uids).join delim
      puts [unfriends.size, unfriendships.size, TwitterUser.calc_removing_uids(uid).size].inspect
      puts

      puts %w(unfollowers unfollowerships calc_removed_uids).join delim
      puts [unfollowers.size, unfollowerships.size, TwitterUser.calc_removed_uids(uid).size].inspect
      puts

      puts %w(one_sided_friends one_sided_friendships calc_one_sided_friend_uids).join delim
      puts [one_sided_friends.size, one_sided_friendships.size, calc_one_sided_friend_uids.size].inspect
      puts

      puts %w(one_sided_followers one_sided_followerships calc_one_sided_follower_uids).join delim
      puts [one_sided_followers.size, one_sided_followerships.size, calc_one_sided_follower_uids.size].inspect
      puts

      puts %w(mutual_friends mutual_friendships calc_mutual_friend_uids).join delim
      puts [mutual_friends.size, mutual_friendships.size, calc_mutual_friend_uids.size].inspect
      puts

      puts %w(inactive_friends inactive_friendships calc_inactive_friend_uids).join delim
      puts [inactive_friends.size, inactive_friendships.size, calc_inactive_friend_uids.size].inspect
      puts

      puts %w(inactive_followers inactive_followerships calc_inactive_follower_uids).join delim
      puts [inactive_followers.size, inactive_followerships.size, calc_inactive_follower_uids.size].inspect
      puts

      puts %w(inactive_mutual_friends inactive_mutual_friendships calc_inactive_mutual_friend_uids).join delim
      puts [inactive_mutual_friends.size, inactive_mutual_friendships.size, calc_inactive_mutual_friend_uids.size].inspect
      puts

      puts %w(replying_uids replying).join delim
      puts [replying_uids.size, replying.size].inspect
      puts

      puts %w(replied_uids replied).join delim
      puts [replied_uids.size, replied.size].inspect
      puts

      puts %w(favorite_friend_uids favorite_friends).join delim
      puts [favorite_friend_uids.size, favorite_friends.size].inspect
    end
  end

  %i(consistent? need_repair? debug_print_friends debug_print).each do |name|
    alias_method "orig_#{name}", name
    define_method(name) do |*args|
      Rails.logger.silence { send("orig_#{name}", *args) }
    end
  end
end
