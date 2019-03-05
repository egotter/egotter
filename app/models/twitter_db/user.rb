# == Schema Information
#
# Table name: twitter_db_users
#
#  id             :bigint(8)        not null, primary key
#  uid            :bigint(8)        not null
#  screen_name    :string(191)      not null
#  friends_size   :integer          default(0), not null
#  followers_size :integer          default(0), not null
#  user_info      :text(65535)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_twitter_db_users_on_created_at   (created_at)
#  index_twitter_db_users_on_screen_name  (screen_name)
#  index_twitter_db_users_on_uid          (uid) UNIQUE
#

module TwitterDB
  class User < ApplicationRecord
    include Concerns::TwitterDB::User::Store
    include Concerns::TwitterUser::Inflections
    include Concerns::TwitterDB::User::Associations
    include Concerns::TwitterDB::User::Importable

    include Concerns::TwitterDB::User::Batch
    include Concerns::TwitterDB::User::Debug

    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    validates_with Validations::UserInfoValidator

    def to_param
      screen_name
    end

    def friend_uids
      friendships.pluck(:friend_uid)
    end

    def follower_uids
      followerships.pluck(:follower_uid)
    end

    class << self
      def with_friends
        # friends_size != -1 AND followers_size != -1
        where.not(friends_size: -1, followers_size: -1)
      end

      def friendless
        where(friends_size: -1, followers_size: -1)
      end
    end

    def with_friends?
      friends_size != -1 && followers_size != -1
    end
  end
end
