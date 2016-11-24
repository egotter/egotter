# `module Twitter` is reserved for `Twitter gem`
module TwitterDB
  class User < ActiveRecord::Base
    establish_connection :twitter
    self.table_name = 'users'

    with_options class_name: "TwitterDB::User", foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_and_belongs_to_many :friends,   join_table: :friends_users,   association_foreign_key: :friend_uid
      obj.has_and_belongs_to_many :followers, join_table: :followers_users, association_foreign_key: :follower_uid
    end

    alias_method :friend_uids, :friend_ids
    alias_method :friend_uids=, :friend_ids=
    alias_method :follower_uids, :follower_ids
    alias_method :follower_uids=, :follower_ids=
  end
end
