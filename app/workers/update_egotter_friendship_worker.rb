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

  # options:
  def perform(user_id, options = {})
    user = client = nil
    user = User.find(user_id)

    client = user.api_client.twitter
    verify_credentials(client)
    update_friendship(client, user)

  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e)
      user&.update!(authorized: false)
    elsif TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.retry_timeout?(e)
      # Do nothing
    else
      Airbag.exception e, user_id: user_id, options: options
    end
  end

  private

  def verify_credentials(client)
    client.verify_credentials
  rescue => e
    raise unless TwitterApiStatus.too_many_requests?(e)
  end

  def update_friendship(client, user)
    if client.friendship?(user.uid, User::EGOTTER_UID)
      CreateEgotterFollowerWorker.perform_async(user.id)
    else
      DeleteEgotterFollowerWorker.perform_async(user.id)
    end
  end
end
