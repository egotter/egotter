module TwitterDB
  class Users
    # `follower_ids` includes suspended uids.
    # `followers` does not include suspended uids.
    # `followers_count` is ambiguous.
    def self.fetch_and_import(uids, client:)
      Batch.fetch_and_import(uids, client: client)
    end

    class Batch
      def self.fetch_and_import(uids, client:)
        uids = uids.uniq.map(&:to_i)
        users = client.users(uids)
        imported = import(users)
        import_suspended(uids - users.map(&:id)) if uids.size != imported.size
      end

      def self.import(t_users)
        users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
        users.sort_by!(&:first)
        TwitterDB::User.import_in_batches(users)
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
    end
  end
end
