require 'active_support/concern'

module Concerns::TwitterDB::User::Batch
  extend ActiveSupport::Concern

  # `follower_ids` includes suspended uids.
  # `followers` does not include suspended uids.
  # `followers_count` is ambiguous.
  class Batch
    def self.fetch_and_create(uid, client:)
      fetch_and_import([uid], client: client)
    end

    def self.fetch_and_import(uids, client:)
      uids = uids.uniq.map(&:to_i)
      users = fetch(uids, client: client)
      imported = import(users)
      import_suspended(uids - users.map { |u| u[:id] }) if uids.size != imported.size
    end

    class << self
      %i(fetch_and_create fetch_and_import).each do |name|
        alias_method "orig_#{name}", name
        define_method(name) do |*args|
          Rails.logger.silence(Logger::WARN) { send("orig_#{name}", *args) }
        end
      end
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
      users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
      users.sort_by!(&:first)
      begin
        tries ||= 3
        TwitterDB::User.import_in_batches(users)
      rescue => e
        if retryable_deadlock?(e)
          if (tries -= 1).zero?
            logger "#{self}##{__method__}: Retry exhausted #{t_users.size} #{t_users.first.inspect.truncate(100)}"
            raise
          else
            sleep(rand * 5)
            retry
          end
        else
          raise
        end
      end
      users
    end

    def self.import_suspended(uids)
      filtered = uids.uniq.map(&:to_i) - TwitterDB::User.where(uid: uids).pluck(:uid)
      return [] if filtered.empty?

      if filtered.size >= 10
        logger "#{self}##{__method__}: Too many suspended uids #{filtered.size} #{filtered.inspect.truncate(100)}"
      end

      t_users =  filtered.map { |uid| Hashie::Mash.new(id: uid, screen_name: 'suspended', description: '') }
      # logger "#{self}##{__method__}: Import suspended uids #{filtered.inspect.truncate(100)}" if filtered.any?
      import(t_users)
      filtered
    end

    private

    def self.logger(message)
      File.basename($0) == 'rake' ? puts(message) : Rails.logger.warn(message)
    end

    def self.retryable_deadlock?(ex)
      ex.class == ActiveRecord::StatementInvalid &&
        ex.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
    end
  end
end
