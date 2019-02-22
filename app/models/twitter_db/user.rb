# == Schema Information
#
# Table name: twitter_db_users
#
#  id             :bigint(8)        not null, primary key
#  followers_size :integer          default(0), not null
#  friends_size   :integer          default(0), not null
#  screen_name    :string(191)      not null
#  uid            :bigint(8)        not null
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
    include Concerns::TwitterUser::Store
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

    CREATE_COLUMNS = %i(uid screen_name user_info friends_size followers_size)
    UPDATE_COLUMNS = %i(uid screen_name user_info)
    BATCH_SIZE = 1000

    class << self
      # Note: This method uses index_twitter_db_users_on_uid.
      def import_in_batches(users)
        persisted_uids = where(uid: users.map(&:first), updated_at: 1.weeks.ago..Time.zone.now).pluck(:uid)
        import(CREATE_COLUMNS, users.reject { |v| persisted_uids.include? v[0] }, on_duplicate_key_update: UPDATE_COLUMNS, batch_size: BATCH_SIZE, validate: false)
      end

      def to_import_format(t_user)
        [t_user[:id], t_user[:screen_name], TwitterUser.collect_user_info(t_user), -1, -1]
      end

      def to_save_format(t_user)
        {uid: t_user[:id], screen_name: t_user[:screen_name], user_info: TwitterUser.collect_user_info(t_user), friends_size: -1, followers_size: -1}
      end

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
