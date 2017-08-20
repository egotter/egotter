require 'active_support/concern'

module Concerns::TwitterUser::Batch
  extend ActiveSupport::Concern

  class Batch
    def self.fetch_and_create(uid)
      user = User.authorized.find_by(uid: uid)
      user = OldUser.authorized.find_by(uid: uid) unless user
      client = user ? user.api_client : Bot.api_client

      begin
        tries ||= 3
        t_user = client.user(uid)
      rescue => e
        if e.message == 'Invalid or expired token.'
          user&.update(authorized: false)
          logger "Invalid token(user) #{uid}"
        elsif e.message == 'Not authorized.'
          logger "Not authorized #{uid}"
        elsif e.message == 'User not found.'
          logger "Not found #{uid}"
        elsif e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
          logger "Temporarily locked #{uid}"
        elsif retryable?(e)
          (tries -= 1).zero? ? logger("Retry limit exceeded(user) #{uid}") : retry
        else
          logger "client.user: #{e.class} #{e.message} #{uid}"
        end

        return
      end

      twitter_user = TwitterUser.build_by_user(t_user)
      twitter_user.user_id = user ? user.id : -1

      if t_user.suspended
        create_friendless_record(twitter_user)
        logger "Suspended#{'(create)' if twitter_user.persisted?} #{uid}"
        return twitter_user.persisted? ? twitter_user : nil
      end

      if t_user.protected && client.verify_credentials.id != t_user.id
        friendship_uid = TwitterDB::Friendship.where(user_uid: User.authorized.pluck(:uid), friend_uid: uid).first&.user_uid
        if friendship_uid
          logger "Change a client to update #{uid} from #{client.verify_credentials.id} to #{friendship_uid}"
          client = User.find_by(uid: friendship_uid).api_client
        else
          create_friendless_record(twitter_user)
          logger "Protected#{'(create)' if twitter_user.persisted?} #{uid}"
          return twitter_user.persisted? ? twitter_user : nil
        end
      end

      if twitter_user.too_many_friends?(login_user: user)
        create_friendless_record(twitter_user)
        logger "Too many friends#{'(create)' if twitter_user.persisted?} #{uid}"
        return twitter_user.persisted? ? twitter_user : nil
      end

      tries = 3
      begin
        signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
        friend_uids, follower_uids = client._fetch_parallelly(signatures)
      rescue => e
        if e.message == 'Invalid or expired token.'
          user&.update(authorized: false)
          logger "Invalid token(friend_ids) #{uid}"
        elsif retryable?(e)
          (tries -= 1).zero? ? logger("Retry limit exceeded(friend_ids) #{uid}") : retry
        else
          logger "client.friend_ids: #{e.class} #{e.message} #{uid}"
        end

        return
      end

      if (t_user.friends_count - friend_uids.size).abs >= 5 || (t_user.followers_count - follower_uids.size).abs >= 5
        return logger "Inconsistent #{uid} [#{t_user.friends_count}, #{friend_uids.size}] [#{t_user.followers_count}, #{follower_uids.size}]"
      end

      if twitter_user_changed?(uid, friend_uids, follower_uids)
        create_twitter_user(twitter_user, friend_uids, follower_uids)
      else
        logger "Not changed #{uid}"
      end

      create_twitter_db_user(twitter_user, friend_uids, follower_uids, client: client)

      twitter_user.persisted? ? twitter_user : nil
    end

    class << self
      %i(fetch_and_create).each do |name|
        alias_method "orig_#{name}", name
        define_method(name) do |*args|
          Rails.logger.silence(Logger::WARN) { send("orig_#{name}", *args) }
        end
      end
    end

    private

    def self.retryable?(ex)
      # Twitter::Error::InternalServerError Internal error
      # Twitter::Error::ServiceUnavailable Over capacity
      # Twitter::Error execution expired

      ['Internal error', 'Over capacity', 'execution expired'].include? ex.message
    end

    def self.create_friendless_record(twitter_user)
      ActiveRecord::Base.transaction do
        unless TwitterUser.exists?(uid: twitter_user.uid)
          twitter_user.assign_attributes(friends_size: 0, followers_size: 0)
          twitter_user.save!(validate: false)
        end

        user = TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid)
        user.assign_attributes(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info)
        user.assign_attributes(friends_size: -1, followers_size: -1) if user.new_record?
        user.save!
      end
    end

    def self.create_twitter_user(twitter_user, friend_uids, follower_uids)
      begin
        ActiveRecord::Base.transaction do
          twitter_user.assign_attributes(friends_size: friend_uids.size, followers_size: follower_uids.size)
          twitter_user.save!(validate: false)
          Friendships.import(twitter_user.id, friend_uids, follower_uids)
        end
      rescue => e
        logger "Friendships.import: #{e.class} #{e.message.truncate(100)} #{twitter_user.uid}"
        return
      end

      uid = twitter_user.uid.to_i

      begin
        Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid))
        Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid))

        OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
        OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
        MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)
      rescue => e
        logger "Unfriendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
      end
    end

    def self.create_twitter_db_user(twitter_user, friend_uids, follower_uids, client:)
      begin
        TwitterDB::User::Batch.fetch_and_import((friend_uids + follower_uids).uniq, client: client)
      rescue => e
        logger "TwitterDB::User::Batch.fetch_and_import: #{e.class} #{e.message.truncate(100)} #{twitter_user.uid}"
        return
      end

      begin
        ActiveRecord::Base.transaction do
          TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid).update!(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: friend_uids.size, followers_size: follower_uids.size)
          TwitterDB::Friendships.import(twitter_user.uid, friend_uids, follower_uids)
        end
      rescue => e
        logger "TwitterDB::Friendships.import: #{e.class} #{e.message.truncate(100)} #{twitter_user.uid}"
      end
    end

    def self.twitter_user_changed?(uid, friend_uids, follower_uids)
      twitter_user = TwitterUser.latest(uid)
      twitter_user.nil? ||
        twitter_user.friendships.pluck(:friend_uid) != friend_uids ||
        twitter_user.followerships.pluck(:follower_uid) != follower_uids
    end

    def self.logger(message)
      File.basename($0) == 'rake' ? puts(message) : Rails.logger.warn(message)
    end
  end
end
