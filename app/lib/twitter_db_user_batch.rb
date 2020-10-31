class TwitterDBUserBatch

  UPDATE_RECORD_INTERVAL = 6.hours

  # `follower_ids` includes suspended uids.
  # `followers` does not include suspended uids.
  # `followers_count` is ambiguous.

  def initialize(client)
    @client = client
  end

  def import!(uids, force_update: false)
    uids = uids.uniq.map(&:to_i)
    users = fetch_users(uids)
    imported = import_users(users, force_update)
    import_suspended_users(uids - users.map { |u| u[:id] }) if uids.size != imported.size
  end

  private

  def fetch_users(uids)
    # Disable the cache
    @client.twitter.users(uids).map(&:to_h)
  rescue => e
    if TwitterApiStatus.no_user_matches?(e)
      []
    else
      raise
    end
  end

  def import_users(users, force_update)
    unless force_update
      # Note: This query uses the index on uid instead of the index on updated_at.
      persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }, updated_at: UPDATE_RECORD_INTERVAL.ago..Time.zone.now).pluck(:uid)
      users.reject! { |user| persisted_uids.include? user[:id] }
    end

    begin
      TwitterDB::User.import_by!(users: users)
    rescue => e
      handle_exception(e)
      sleep(sleep_in)
      retry
    end

    users
  end

  def import_suspended_users(uids)
    not_persisted = uids.uniq.map(&:to_i) - TwitterDB::User.where(uid: uids).pluck(:uid)
    return [] if not_persisted.empty?

    t_users = not_persisted.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
    import_users(t_users, false)

    if not_persisted.size >= 10
      logger.warn { "#{self.class}##{__method__} #{not_persisted.size} records" }
    end

    not_persisted
  end

  def handle_exception(e)
    @retry_count ||= 3

    if !deadlock_exception?(e) || (@retry_count -= 1) <= 0
      raise RetryExhausted.new(e.inspect.truncate(200))
    end
  end

  def sleep_in
    rand(3) + 1
  end

  # ActiveRecord::StatementInvalid
  # ActiveRecord::Deadlocked
  def deadlock_exception?(ex)
    ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
  end

  def logger
    Rails.logger
  end

  class RetryExhausted < StandardError; end

  module Instrumentation
    def bm(message, &block)
      start = Time.zone.now
      result = yield
      @benchmark[message.to_s] = Time.zone.now - start if @benchmark
      result
    end

    def fetch_users(*args)
      bm(__method__) { super }
    end

    def import_users(*args)
      bm(__method__) { super }
    end

    def import_suspended_users(*args)
      bm(__method__) { super }
    end

    def import!(*args, &blk)
      @benchmark = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @benchmark['sum'] = @benchmark.values.sum
      @benchmark['elapsed'] = elapsed
      @benchmark.transform_values! { |v| sprintf("%.3f", v) }

      logger.info "Benchmark TwitterDBUserBatch #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
