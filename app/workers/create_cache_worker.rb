class CreateCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(values)
    values = values.with_indifferent_access
    values['user_id']
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(*args)
    logger.info "Timeout #{timeout_in} #{args.inspect.truncate(100)}"
  end

  def expire_in
    1.minute
  end

  def perform(values)
    user_id = values['user_id']
    user = User.find(user_id)
    threads = []

    TwitterUser.select(:id).where(uid: user.uid).order(created_at: :desc).each do |twitter_user|
      [S3::Friendship, S3::Followership, S3::Profile].each do |klass|
        threads << Proc.new do
          klass.find_by!(twitter_user_id: twitter_user.id)
        rescue Aws::S3::Errors::NoSuchKey => e
          logger.warn "#{e.class} #{e.message} Please check whether the TwitterUser exists or not. #{klass} #{twitter_user.id} #{values}"
        end
      end
    end

    # twitter_db_user = TwitterDB::User.select(:id).find_by(uid: user.uid)
    # [TwitterDB::S3::Friendship, TwitterDB::S3::Followership, TwitterDB::S3::Profile].each do |klass|
    #   threads << Proc.new do
    #     klass.delete_cache_by(uid: user.uid)
    #     klass.find_by(uid: user.uid)
    #   end
    # end

    client = user.api_client
    threads << Proc.new {client.user}
    threads << Proc.new {client.user(user.uid)}
    threads << Proc.new {client.user(user.screen_name)}

    Parallel.each(threads, in_threads: 3, &:call)

  rescue Twitter::Error::NotFound => e
    if e.message == 'User not found.'
      logger.info "#{e.class}: #{e.message} #{values}"
    else
      logger.warn "#{e.class}: #{e.message} #{values}"
    end
    logger.info e.backtrace.join("\n")
  rescue Twitter::Error::Unauthorized => e
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{e.class}: #{e.message} #{values}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{values}"
    logger.info e.backtrace.join("\n")
  end
end
