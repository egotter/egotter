module TwitterDB
  class User < TwitterDB::Base
    include Concerns::TwitterUser::Store
    include Concerns::TwitterUser::Inflections

    with_options primary_key: :uid, foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }
      obj.has_many :followerships, -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships
      obj.has_many :followers, through: :followerships
    end

    alias_method :friend_uids, :friend_ids
    alias_method :friend_uids=, :friend_ids=
    alias_method :follower_uids, :follower_ids
    alias_method :follower_uids=, :follower_ids=

    def self.find_or_import_by(twitter_user)
      import_from!([twitter_user]) unless exists?(uid: twitter_user.uid)
      find_by(uid: twitter_user.uid)
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

    def self.import_from_old!(users_array)
      return if users_array.empty?

      uids = users_array.map(&:uid).map(&:to_i)
      users = where(uid: uids)
      users += (uids - users.map(&:uid)).map { |uid| new(uid: uid) }
      users = users.index_by(&:uid)

      users_array.each do |u|
        user = users[u.uid.to_i]
        if user.new_record?
          user.assign_attributes(
            screen_name: u.screen_name,
            friends_size: -1,
            followers_size: -1,
            user_info: u.user_info,
            created_at: u.created_at,
            updated_at: u.created_at
          )
        else
          if user.updated_at < u.created_at
            user.assign_attributes(
              screen_name: u.screen_name,
              user_info: u.user_info,
              updated_at: u.created_at
            )
          end
        end
      end

      changed, not_changed = users.values.partition { |u| u.changed? }
      new_record, persisted = changed.partition { |u| u.new_record? }
      if new_record.any?
        import(new_record, validate: false, timestamps: false)
      end
      if persisted.any?
        import(persisted, on_duplicate_key_update: %i(screen_name user_info updated_at), validate: false, timestamps: false)
      end
      result = "#{Time.zone.now} users(#{users_array.first.class}): #{users.size}, changed: #{changed.size}(#{new_record.size}, #{persisted.size}), not_changed: #{not_changed.size}, #{users_array[0].id} - #{users_array[-1].id}"
      Rails.env.test? ? puts(result) : logger.info(result)
    end
  end
end
