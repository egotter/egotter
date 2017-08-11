class TwitterUsers
  def self.fetch_and_create(uid)
    user = User.authorized.find_by(uid: uid)
    client = user ? user.api_client : Bot.api_client

    begin
      t_user = client.user(uid)
    rescue => e
      if e.message == 'Invalid or expired token.'
        user&.update(authorized: false)
        logger "Invalid token(user) #{uid}"
      elsif ['Not authorized.', 'User not found.'].include? e.message
        logger "Not authorized or Not found #{uid}"
      elsif e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
        logger "Temporarily locked #{uid}"
      else
        logger "client.user: #{e.class} #{e.message} #{uid}"
      end

      # Twitter::Error execution expired
      # Twitter::Error::InternalServerError Internal error

      return
    end

    twitter_user = TwitterUser.build_by_user(t_user)
    twitter_user.user_id = user ? user.id : -1

    if t_user.suspended
      create_friendless_record(twitter_user)
      return logger "Create suspended #{uid}"
    end

    if t_user.protected && client.verify_credentials.id != t_user.id
      friendship_uid = TwitterDB::Friendship.where(user_uid: User.authorized.pluck(:uid), friend_uid: uid).first&.user_uid
      if friendship_uid
        logger "Change a client to update #{uid} from #{client.verify_credentials.id} to #{friendship_uid}"
        client = User.find_by(uid: friendship_uid).api_client
      else
        create_friendless_record(twitter_user)
        return logger "Create protected #{uid}"
      end
    end

    if twitter_user.too_many_friends?(login_user: user)
      create_friendless_record(twitter_user)
      return logger "Create too many friends #{uid}"
    end

    begin
      signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
      friend_uids, follower_uids = client._fetch_parallelly(signatures)
    rescue => e
      if e.message == 'Invalid or expired token.'
        user&.update(authorized: false)
        return logger "Invalid token(friend_ids) #{uid}"
      else
        return logger "client.friend_ids: #{e.class} #{e.message} #{uid}"
      end
    end

    if (t_user.friends_count - friend_uids.size).abs >= 5 || (t_user.followers_count - follower_uids.size).abs >= 5
      return logger "Inconsistent #{uid} [#{t_user.friends_count}, #{friend_uids.size}] [#{t_user.followers_count}, #{follower_uids.size}]"
    end

    begin
      ActiveRecord::Base.transaction do
        twitter_user.update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
        Friendships.import(twitter_user.id, friend_uids, follower_uids)
      end
    rescue => e
      return logger "Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

    begin
      Rails.logger.silence { TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client) }
    rescue => e
      return logger "TwitterDB::Users.fetch_and_import: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

    begin
      ActiveRecord::Base.transaction do
        TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid).update!(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: friend_uids.size, followers_size: follower_uids.size)
        TwitterDB::Friendships.import(twitter_user.uid, friend_uids, follower_uids)
      end
    rescue => e
      return logger "TwitterDB::Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

    twitter_user
  end

  private

  def self.create_friendless_record(twitter_user)
    ActiveRecord::Base.transaction do
      twitter_user.update!(friends_size: 0, followers_size: 0)
      unless TwitterDB::User.exists?(uid: twitter_user.uid)
        TwitterDB::User.create!(uid: twitter_user.uid, screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: -1, followers_size: -1)
      end
    end
  end

  def self.logger(message)
    File.basename($0) == 'rake' ? puts(message) : Rails.logger.warn(message)
  end
end
