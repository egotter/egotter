require 'active_support/concern'

module Concerns::TwitterDB::User::Batch
  extend ActiveSupport::Concern

  # `follower_ids` includes suspended uids.
  # `followers` does not include suspended uids.
  # `followers_count` is ambiguous.
  class Batch
    def self.fetch_and_import!(uids, client:)
      uids = uids.uniq.map(&:to_i)
      users = fetch(uids, client: client)
      imported = import(users)
      import_suspended(uids - users.map { |u| u[:id] }) if uids.size != imported.size

      # CreateTwitterDBProfileWorker.perform_async(uids) if uids.any?
    end

    def self.fetch_and_import(uids, client:)
      fetch_and_import!(uids, client: client)
    rescue => e
      logger.warn "#{__method__} #{e.class} #{e.message.truncate(100)} #{uids.inspect.truncate(100)}"
      logger.info e.backtrace.join("\n")
      []
    end

    def self.fetch(uids, client:)
      client.users(uids)
    rescue Twitter::Error::NotFound => e
      if e.message == 'No user matches for specified terms.'
        []
      else
        raise
      end
    end

    def self.import(t_users)
      # Note: This process uses index_twitter_db_users_on_uid instead of index_twitter_db_users_on_updated_at.
      persisted_uids = TwitterDB::User.where(uid: t_users.map {|user| user[:id]}, updated_at: 1.weeks.ago..Time.zone.now).pluck(:uid)

      t_users = t_users.reject {|user| persisted_uids.include? user[:id]}

      users = t_users.map {|user| [user[:id], user[:screen_name], ::TwitterUser.collect_user_info(user), -1, -1]}
      users.sort_by!(&:first)

      profiles = t_users.map {|user| TwitterDB::Profile.build_by_t_user(user)}
      profiles.sort_by!(&:uid)

      begin
        tries ||= 3

        users.each_slice(500) do |users_group|
          target_uids = users_group.map(&:first)

          ApplicationRecord.transaction do
            TwitterDB::User.import(CREATE_COLUMNS, users_group, on_duplicate_key_update: UPDATE_COLUMNS, batch_size: 500, validate: false)
            TwitterDB::Profile.import profiles.select {|p| target_uids.include?(p.uid)}, batch_size: 500, validate: false
          end
        end
      rescue => e
        if retryable_deadlock?(e)
          message = "#{self}##{__method__}: #{e.class} #{e.message.truncate(100)} #{t_users.size}"

          if (tries -= 1) < 0
            logger.warn "RETRY EXHAUSTED #{message}"
            raise
          else
            logger.warn "RETRY #{tries} #{message}"
            sleep(rand * 5)
            retry
          end
        else
          raise
        end
      end
      users
    end

    CREATE_COLUMNS = %i(uid screen_name user_info friends_size followers_size)
    UPDATE_COLUMNS = %i(uid screen_name user_info)

    def self.import_suspended(uids)
      not_persisted = uids.uniq.map(&:to_i) - TwitterDB::User.where(uid: uids).pluck(:uid)
      return [] if not_persisted.empty?

      t_users =  not_persisted.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
      import(t_users)

      if not_persisted.size >= 10
        logger.warn {"#{self.class}##{__method__} #{not_persisted.size} records"}
      else
        logger.info {"#{self.class}##{__method__} #{not_persisted.size} records"}
      end

      not_persisted
    end

    private

    def self.logger
      @@logger ||= (File.basename($0) == 'rake' ? Logger.new(STDOUT) : Rails.logger)
    end

    def self.retryable_deadlock?(ex)
      (ex.class == ActiveRecord::StatementInvalid && ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')) ||
          (ex.class == ActiveRecord::Deadlocked &&   ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction'))
    end
  end
end
