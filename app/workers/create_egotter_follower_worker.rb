class CreateEgotterFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def sleep_in
    rand(3) + 1.second
  end

  def perform(user_id, options = {})
    user = User.find(user_id)
    if EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.find_by(uid: user.uid).touch
    else
      EgotterFollower.create!(uid: user.uid, screen_name: user.screen_name)
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.info "Record is not unique #{e.inspect} user_id=#{user_id} options=#{options.inspect}"
  rescue ActiveRecord::Deadlocked => e
    # Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction:
    @retry_count ||= 0
    if @retry_count < 3
      sleep(sleep_in)
      @retry_count += 1
      retry
    else
      logger.warn "Retry exhausted #{e.inspect} retry_count=#{@retry_count} user_id=#{user_id} options=#{options.inspect}"
    end
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
  end
end
