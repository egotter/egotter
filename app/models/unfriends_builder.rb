class UnfriendsBuilder
  def initialize(twitter_user, preload: true)
    @users = TwitterUser.where('created_at <= ?', twitter_user.created_at).creation_completed.where(uid: twitter_user.uid).select(:id).order(created_at: :asc)
  end

  def unfriends
    S3::Friendship.where(twitter_user_ids: @users.map(&:id))
    @users.each_cons(2).map {|older, newer| Util.unfriends(older, newer)}.compact.reverse.flatten
  end

  def unfollowers
    S3::Followership.where(twitter_user_ids: @users.map(&:id))
    @users.each_cons(2).map {|older, newer| Util.unfollowers(older, newer)}.compact.reverse.flatten
  end

  module Util
    module_function

    def unfriends(older, newer)
      newer ? older.friend_uids - newer.friend_uids : nil
    end

    def unfollowers(older, newer)
      newer ? older.follower_uids - newer.follower_uids : nil
    end
  end
end
