class CreateTwitterDBUsersTask

  # TODO Remove :force option
  def initialize(uids, user_id: nil, force: false)
    @uids = uids.uniq.map(&:to_i)
    @client = user_id ? User.find(user_id).api_client : Bot.api_client
    @force = force
    Rails.logger.info "CreateTwitterDBUsersTask: The :force option is true" if @force
  end

  def start
    @uids = reject_fresh_uids(@uids)
    users = fetch_users(@client, @uids)

    if @uids.size != users.size && (suspended_uids = @uids - users.map { |u| u[:id] }).any?
      import_suspended_users(suspended_uids)
    end

    users = reject_fresh_users(users) unless @force
    import_users(users) if users.any?
  end

  private

  def fetch_users(client, uids)
    retries ||= 3
    client.twitter.users(uids).map(&:to_h)
  rescue => e
    if TwitterApiStatus.no_user_matches?(e)
      []
    elsif retryable_twitter_error?(e)
      if (retries -= 1) >= 0
        client = Bot.api_client
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    else
      raise
    end
  end

  def import_users(users)
    TwitterDB::User.import_by!(users: users)
  rescue => e
    if deadlock_error?(e)
      raise RetryDeadlockExhausted.new(e.inspect)
    else
      raise
    end
  end

  def import_suspended_users(uids)
    Rails.logger.info "Import suspended uids size=#{uids.size} ids=#{uids.inspect}"
    users = uids.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
    users = reject_persisted_users(users)
    TwitterDB::User.import_by!(users: users) if users.any?
  end

  # Note: This query uses the index on uid instead of the index on updated_at.
  def reject_fresh_uids(uids)
    fresh_uids = TwitterDB::User.where(uid: uids).where('updated_at > ?', 6.hours.ago).pluck(:uid)
    Rails.logger.info "Reject fresh uids passed=#{uids.size} persisted=#{fresh_uids.size}"
    uids.reject { |uid| fresh_uids.include? uid }
  end

  # Note: This query uses the index on uid instead of the index on updated_at.
  def reject_fresh_users(users)
    persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }).where('updated_at > ?', 6.hours.ago).pluck(:uid)
    Rails.logger.info "Reject fresh users passed=#{users.size} persisted=#{persisted_uids.size}"
    users.reject { |user| persisted_uids.include? user[:id] }
  end

  def reject_persisted_users(users)
    # Note: This query uses the index on uid instead of the index on updated_at.
    persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }).pluck(:uid)
    Rails.logger.info "Reject persisted users passed=#{users.size} persisted=#{persisted_uids.size}"
    users.reject { |user| persisted_uids.include? user[:id] }
  end

  # ActiveRecord::StatementInvalid
  # ActiveRecord::Deadlocked
  def deadlock_error?(e)
    e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
  end

  def retryable_twitter_error?(e)
    TwitterApiStatus.unauthorized?(e) ||
        TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.forbidden?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        ServiceStatus.retryable_error?(e)
  end

  class RetryExhausted < StandardError; end

  class RetryDeadlockExhausted < StandardError; end
end
