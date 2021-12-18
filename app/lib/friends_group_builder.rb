# TODO Remove later
class FriendsGroupBuilder
  def initialize(uid, limit: nil, users: nil)
    @users = users
  end

  # New friends between old record and new record
  def new_friends
    @users.each_cons(2).map { |older, newer| Util.new_friends(older, newer) }.compact.tap { |ary| ary.prepend([]) if ary.empty? }
  end

  # New followers between old record and new record
  def new_followers
    @users.each_cons(2).map { |older, newer| Util.new_followers(older, newer) }.compact.tap { |ary| ary.prepend([]) if ary.empty? }
  end

  module Util
    module_function

    def new_friends(older, newer)
      newer ? newer.friend_uids - older.friend_uids : nil
    end

    def new_followers(older, newer)
      newer ? newer.follower_uids - older.follower_uids : nil
    end
  end
end
