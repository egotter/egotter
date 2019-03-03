class CreateCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(values)
    user_id = values['user_id']
    queue = RunningQueue.new(self.class)
    return if queue.exists?(user_id)
    queue.add(user_id)

    if values['enqueued_at'].blank? || Time.zone.parse(values['enqueued_at']) < Time.zone.now - 1.minute
      logger.info {"Don't run this job since it is too late."}
      return
    end

    ApplicationRecord.benchmark("#{self.class} Create cache #{values}", level: :debug) do
      Timeout.timeout(10) do
        do_perform(values)
      end
    end
  rescue Timeout::Error => e
    logger.info "#{e.class}: #{e.message} #{values}"
    logger.info e.backtrace.join("\n")
  end

  def do_perform(values)
    user_id = values['user_id']
    user = User.find(user_id)
    threads = []

    TwitterUser.select(:id).where(uid: user.uid).order(created_at: :desc).each do |twitter_user|
      [S3::Friendship, S3::Followership, S3::Profile].each do |klass|
        threads << Proc.new {klass.find_by(twitter_user_id: twitter_user.id)}
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
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    else
      logger.warn "#{e.class}: #{e.message} #{values}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{values}"
    logger.info e.backtrace.join("\n")
  end
end
