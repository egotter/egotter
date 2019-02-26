class ImportS3FollowershipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id, follower_uids)
    twitter_user = TwitterUser.select(:id, :uid, :screen_name).find(twitter_user_id)
    S3::Followership.import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, follower_uids)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id} #{follower_uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end
