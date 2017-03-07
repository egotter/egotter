class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    twitter_user = TwitterUser.latest(uid)

    ImportReplyingRepliedAndFavoritesWorker.perform_async(user_id, uid)

    if twitter_user.friendless?
      ImportUserWorker.perform_async(user_id, uid)
    else
      client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
      signatures = [{method: :user, args: [uid]}, {method: :friends, args: [uid]}, {method: :followers, args: [uid]}]
      client._fetch_parallelly(signatures) # create caches

      ImportFriendshipsAndFollowershipsWorker.perform_async(user_id, uid)
      ImportFriendsAndFollowersWorker.perform_async(user_id, uid)
      ImportInactiveFriendsAndInactiveFollowersWorker.perform_async(user_id, uid)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
  end
end
