class RepairTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id)
    twitter_user = TwitterUser.find(twitter_user_id)

    raise "#{twitter_user_id} is valid." if twitter_user.valid_friendships_counter_cache? && twitter_user.valid_followerships_counter_cache?

    if twitter_user.latest?
      uid = twitter_user.uid.to_i
      user = User.find_by(id: twitter_user.user_id, authorized: true)
      client = user ? user.api_client : Bot.api_client
      not_found = false

      begin
        client.verify_credentials.id
      rescue Twitter::Error::Unauthorized => e
        if e.message == 'Invalid or expired token.'
          user&.update(authorized: false)
          client = Bot.api_client
        else
          raise
        end
      rescue Twitter::Error::NotFound => e
        if e.message == 'Sorry, that page does not exist.'
          not_found = true
        else
          raise
        end
      end

      if not_found
        import_empty_friends(twitter_user)
      else
        signatures = [{method: :user, args: [uid]}, {method: :friend_ids, args: [uid]}, {method: :follower_ids, args: [uid]}]
        t_user, friend_uids, follower_uids = client._fetch_parallelly(signatures)

        import_friends(twitter_user, t_user, friend_uids, follower_uids)
        import_other_friendships(twitter_user)
      end
    else
      import_empty_friends(twitter_user)
    end

    import_unfriendships(twitter_user)

  rescue => e
    puts "#{e.class} #{e.message} #{twitter_user_id}"
  end

  private

  def import_friends(twitter_user, t_user, friend_uids, follower_uids)
    _transaction('import Friendship and Followership') do
      twitter_user.update!(user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: friend_uids.size, followers_size: follower_uids.size)
      Friendship.import_from!(twitter_user.id, friend_uids)
      Followership.import_from!(twitter_user.id, follower_uids)
    end
  end

  def import_empty_friends(twitter_user)
    _transaction('import Friendship and Followership') do
      twitter_user.update!(friends_size: 0, followers_size: 0)
      Friendship.import_from!(twitter_user.id, [])
      Followership.import_from!(twitter_user.id, [])
    end
  end

  def import_unfriendships(twitter_user)
    uid = twitter_user.uid.to_i

    _benchmark('import Unfriendship') { Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid)) }
    _benchmark('import Unfollowership') { Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid)) }
  end

  def import_other_friendships(twitter_user)
    uid = twitter_user.uid.to_i

    _benchmark('import OneSidedFriendship') { OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids) }
    _benchmark('import OneSidedFollowership') { OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids) }
    _benchmark('import MutualFriendship') { MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids) }
  end
end
