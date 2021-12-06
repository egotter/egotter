class UpdateLockedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    5.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    user.api_client.users([user.id])
  rescue => e
    if TwitterApiStatus.temporarily_locked?(e)
      user.update!(locked: true)
    elsif TwitterApiStatus.not_found?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        TwitterApiStatus.no_user_matches?(e)
      # Do nothing
    else
      Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
      Airbag.info e.backtrace.join("\n")
    end
  end
end
