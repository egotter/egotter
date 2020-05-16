class UpdateEgotterFriendshipWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    10.minutes
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(user_id, options = {})
    UpdateEgotterFriendshipWorker.perform_in(2.minutes, user_id, options)
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)

    client = user.api_client.twitter
    client.verify_credentials

    if client.friendship?(user.uid, User::EGOTTER_UID)
      CreateEgotterFollowerWorker.perform_async(user.id)
    else
      DeleteEgotterFollowerWorker.perform_async(user.id)
    end
  rescue => e
    if AccountStatus.invalid_or_expired_token?(e)
      user.update!(authorized: false)
    elsif AccountStatus.temporarily_locked?(e)
      # Do nothing
    elsif ServiceStatus.connection_reset_by_peer?(e)
      retry
    else
      logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end
