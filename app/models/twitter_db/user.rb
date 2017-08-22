module TwitterDB
  class User < ActiveRecord::Base
    include Concerns::TwitterUser::Store
    include Concerns::TwitterUser::Inflections

    include Concerns::TwitterDB::User::Batch
    include Concerns::TwitterDB::User::Debug

    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    validates_with Validations::UserInfoValidator

    with_options primary_key: :uid, foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }, class_name: 'TwitterDB::Friendship'
      obj.has_many :followerships, -> { order(sequence: :asc) }, class_name: 'TwitterDB::Followership'
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships, class_name: 'TwitterDB::User'
      obj.has_many :followers, through: :followerships, class_name: 'TwitterDB::User'
    end

    def to_param
      screen_name
    end

    CREATE_COLUMNS = %i(uid screen_name user_info friends_size followers_size)
    UPDATE_COLUMNS = %i(uid screen_name user_info)
    BATCH_SIZE = 1000

    # Note: This method uses index_twitter_db_users_on_uid.
    def self.import_in_batches(users)
      persisted_uids = where(uid: users.map(&:first), updated_at: 1.weeks.ago..Time.zone.now).pluck(:uid)
      import(CREATE_COLUMNS, users.reject { |v| persisted_uids.include? v[0] }, on_duplicate_key_update: UPDATE_COLUMNS, batch_size: BATCH_SIZE, validate: false)
    end

    def self.to_import_format(t_user)
      [t_user.id, t_user.screen_name, t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
    end

    def self.to_save_format(t_user)
      {uid: t_user.id, screen_name: t_user.screen_name, user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: -1, followers_size: -1}
    end

    def self.with_friends
      # friends_size != -1 AND followers_size != -1
      where.not(friends_size: -1, followers_size: -1)
    end

    def self.friendless
      where(friends_size: -1, followers_size: -1)
    end

    def with_friends?
      friends_size != -1 && followers_size != -1
    end
  end
end
