class DetectFailureWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def perform(twitter_user_id, options = {})
    user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :created_at).find(twitter_user_id)

    if user.s3_need_fix?
      logger.warn "Failed something. #{twitter_user_id} #{user.created_at} #{user.s3_need_fix_reasons.inspect}"
    end

  rescue ActiveRecord::RecordNotFound => e
    # When the user resets data.
    message = "#{e.class} #{e.message} User probably reset data. #{twitter_user_id} #{options.inspect}"
    if reset_request_found?(options)
      logger.info message
    else
      logger.warn message
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{twitter_user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def reset_request_found?(values)
    ResetEgotterRequest.exists?(user_id: values['user_id'], created_at: 10.minutes.ago..Time.zone.now)
  end
end
