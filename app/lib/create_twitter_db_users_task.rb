class CreateTwitterDBUsersTask
  def initialize(uids, user_id: nil, force: false, enqueued_by: nil)
    @uids = uids.uniq.map(&:to_i)
    @user_id = user_id
    if user_id && !RateLimitExceededFlag.on?(@user_id)
      @client = User.find(user_id).api_client
    else
      @client = Bot.api_client
    end
    @force = force
    @enqueued_by = enqueued_by
  end

  def start
    @uids = reject_fresh_uids(@uids)
    return if @uids.empty?

    begin
      TwitterDB::QueuedUser.import_data(@uids)
    rescue => e
      Airbag.warn "CreateTwitterDBUsersTask#start: #{e.inspect.truncate(200)}"
    end

    users = fetch_users(@client, @uids)

    if @uids.size != users.size && (suspended_uids = @uids - users.map { |u| u[:id] }).any?
      import_suspended_users(suspended_uids)
    end

    return if users.empty?

    users = reject_fresh_users(users) unless @force

    if users.any?
      ImportTwitterDBUserWorker.perform_async(users, enqueued_by: @enqueued_by, _user_id: @user_id)
    end
  end

  private

  def fetch_users(client, uids)
    retries ||= 3
    client.twitter.users(uids).map(&:to_h)
  rescue => e
    if TwitterApiStatus.no_user_matches?(e)
      []
    elsif retryable_twitter_error?(e)
      if TwitterApiStatus.too_many_requests?(e) && @user_id
        RateLimitExceededFlag.on(@user_id)
      end

      if (retries -= 1) >= 0
        Airbag.info { "#{self.class}: Client is switched #{e.inspect} user_id=#{@user_id}" }
        client = Bot.api_client
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    else
      raise
    end
  end

  def import_suspended_users(uids)
    users = uids.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
    users = reject_persisted_users(users)
    TwitterDB::User.import_by!(users: users) if users.any?
  end

  # Note: This query uses the index on uid instead of the index on updated_at.
  def reject_fresh_uids(uids)
    fresh_uids = TwitterDB::User.where(uid: uids).where('updated_at > ?', 6.hours.ago).pluck(:uid)
    uids.reject { |uid| fresh_uids.include? uid }
  end

  # Note: This query uses the index on uid instead of the index on updated_at.
  def reject_fresh_users(users)
    persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }).where('updated_at > ?', 6.hours.ago).pluck(:uid)
    users.reject { |user| persisted_uids.include? user[:id] }
  end

  def reject_persisted_users(users)
    # Note: This query uses the index on uid instead of the index on updated_at.
    persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }).pluck(:uid)
    users.reject { |user| persisted_uids.include? user[:id] }
  end

  def retryable_twitter_error?(e)
    TwitterApiStatus.unauthorized?(e) ||
        TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.forbidden?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        ServiceStatus.retryable_error?(e)
  end

  class RetryExhausted < StandardError; end
end
