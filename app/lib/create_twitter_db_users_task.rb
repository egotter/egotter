class CreateTwitterDBUsersTask
  def initialize(uids, user_id: nil, enqueued_by: nil)
    @uids = uids.uniq.map(&:to_i)
    @user_id = user_id
    @enqueued_by = enqueued_by
  end

  def start
    uids = @uids - TwitterDB::QueuedUser.where(uid: @uids).pluck(:uid)
    return if uids.empty?

    begin
      TwitterDB::QueuedUser.import_data(uids)
    rescue => e
      Airbag.warn "CreateTwitterDBUsersTask#start: #{e.inspect.truncate(200)}"
    end

    users = fetch_users(uids)

    if uids.size != users.size && (suspended_uids = uids - users.map { |u| u[:id] }).any?
      ImportTwitterDBSuspendedUserWorker.perform_async(suspended_uids)
    end

    if users.any?
      # ImportTwitterDBUserWorker.perform_async(users, enqueued_by: @enqueued_by, _user_id: @user_id, _size: users.size)
      ImportTwitterDBUserWorker.perform_in(rand(10) + 3, users, enqueued_by: @enqueued_by, _user_id: @user_id, _size: users.size)
    end
  end

  private

  def fetch_users(uids)
    retries ||= 3
    client.users(uids).map(&:to_h)
  rescue => e
    if TwitterApiStatus.no_user_matches?(e)
      []
    elsif retryable_error?(e)
      if TwitterApiStatus.too_many_requests?(e) && @user_id
        RateLimitExceededFlag.on(@user_id)
      end

      if (retries -= 1) >= 0
        Airbag.info "#{self.class}: Client reloaded", exception: e.inspect, user_id: @user_id
        @client = Bot.api_client.twitter
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    else
      raise
    end
  end

  def client
    @client ||=
        if @user_id && !RateLimitExceededFlag.on?(@user_id)
          User.find(@user_id).api_client.twitter
        else
          Bot.api_client.twitter
        end
  end

  def retryable_error?(e)
    TwitterApiStatus.unauthorized?(e) ||
        TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.forbidden?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        ServiceStatus.retryable_error?(e)
  end

  class RetryExhausted < StandardError; end
end
