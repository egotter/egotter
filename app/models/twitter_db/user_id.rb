# == Schema Information
#
# Table name: twitter_db_user_ids
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_twitter_db_user_ids_on_uid  (uid) UNIQUE
#

module TwitterDB
  class UserId < ApplicationTwitterRecord
    validates :uid, presence: true, uniqueness: true

    COLUMNS = %w(uid)

    class << self
      def import_uids(uids)
        import COLUMNS, uids.map { |id| [id] }, on_duplicate_key_update: %w(uid), batch_size: 100, validate: false
      rescue => e
        if deadlock_error?(e)
          uids.each { |uid| create(uid: uid) }
        else
          raise
        end
      end

      def deadlock_error?(e)
        e.class.name.include?('Deadlocked') || e.message.include?('try restarting transaction') || e.message.include?('Deadlock found')
      end
    end
  end
end
