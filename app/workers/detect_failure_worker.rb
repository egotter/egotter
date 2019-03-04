class DetectFailureWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def perform(twitter_user_id, options = {})
    user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info, :created_at).find(twitter_user_id)

    if user.s3_need_fix?
      logger.warn "Failed something. #{twitter_user_id} #{user.created_at} #{user.s3_need_fix_reasons.inspect}"
    end

  rescue ActiveRecord::RecordNotFound => e
    # When the user reset data.
    raise e
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id}"
    logger.info e.backtrace.join("\n")
  end
end
