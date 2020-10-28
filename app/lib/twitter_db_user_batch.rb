class TwitterDBUserBatch

  UPDATE_RECORD_INTERVAL = 6.hours

  # `follower_ids` includes suspended uids.
  # `followers` does not include suspended uids.
  # `followers_count` is ambiguous.

  class << self
    def fetch_and_import!(uids, client:, force_update: false)
      uids = uids.uniq.map(&:to_i)
      users = fetch(uids, client: client)
      imported = import(users, force_update: force_update)
      import_suspended(uids - users.map { |u| u[:id] }) if uids.size != imported.size
    end

    def fetch(uids, client:)
      # Disable the cache
      client.twitter.users(uids).map(&:to_h)
    rescue => e
      if TwitterApiStatus.no_user_matches?(e)
        []
      else
        raise
      end
    end

    def import(users, force_update: false)
      unless force_update
        # Note: This query uses the index on uid instead of the index on updated_at.
        persisted_uids = TwitterDB::User.where(uid: users.map { |user| user[:id] }, updated_at: UPDATE_RECORD_INTERVAL.ago..Time.zone.now).pluck(:uid)
        users = users.reject { |user| persisted_uids.include? user[:id] }
      end

      retry_importing { TwitterDB::User.import_by!(users: users) }

      users
    end

    def import_suspended(uids)
      not_persisted = uids.uniq.map(&:to_i) - TwitterDB::User.where(uid: uids).pluck(:uid)
      return [] if not_persisted.empty?

      t_users = not_persisted.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
      import(t_users)

      if not_persisted.size >= 10
        logger.warn { "#{self.class}##{__method__} #{not_persisted.size} records" }
      else
        logger.info { "#{self.class}##{__method__} #{not_persisted.size} records" }
      end

      not_persisted
    end

    private

    def logger
      @@logger ||= (File.basename($0) == 'rake' ? Logger.new(STDOUT) : Rails.logger)
    end

    def retry_importing(&block)
      tries ||= 3
      yield
    rescue => e
      if retryable_exception?(e) && (tries -= 1) > 0
        sleep(rand * 5)
        retry
      else
        raise RetryExhausted.new("#{e.class} #{e.message.truncate(100)}")
      end
    end

    def retryable_exception?(ex)
      (ex.class == ActiveRecord::StatementInvalid && ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')) ||
          (ex.class == ActiveRecord::Deadlocked && ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction'))
    end
  end

  class RetryExhausted < StandardError
  end
end
