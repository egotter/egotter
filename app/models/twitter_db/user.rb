module TwitterDB
  class User < ActiveRecord::Base
    self.table_name = 'twitter_db_users'

    include Concerns::TwitterUser::Store
    include Concerns::TwitterUser::Inflections

    with_options primary_key: :uid, foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }, class_name: 'TwitterDB::Friendship'
      obj.has_many :followerships, -> { order(sequence: :asc) }, class_name: 'TwitterDB::Followership'
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships, class_name: 'TwitterDB::User'
      obj.has_many :followers, through: :followerships, class_name: 'TwitterDB::User'
    end

    def self.import_from!(users_array)
      users =
        users_array.map do |user|
          new(uid: user.uid.to_i, screen_name: user.screen_name, friends_size: -1, followers_size: -1, user_info: user.user_info)
        end

      users.each_slice(1000) do |targets|
        import(targets, on_duplicate_key_update: %i(uid screen_name user_info), validate: false)
      end
    end

    CREATE_COLUMNS = %i(uid screen_name user_info friends_size followers_size)
    UPDATE_COLUMNS = %i(uid screen_name user_info)

    def self.import_each_slice(users_array, n: 1000, create_columns: CREATE_COLUMNS, update_columns: UPDATE_COLUMNS)
      users_array.each_slice(n) do |array|
        import(create_columns, array, on_duplicate_key_update: update_columns, validate: false)
      end
    end
  end
end
