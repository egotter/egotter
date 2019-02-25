class ImportDynamodbFriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id, friend_uids)
    twitter_user = TwitterUser.select(:id, :uid, :screen_name).find(twitter_user_id)
    DynamoDB::Friendship.import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, friend_uids)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id} #{friend_uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end
