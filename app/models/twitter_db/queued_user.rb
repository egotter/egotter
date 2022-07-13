# == Schema Information
#
# Table name: twitter_db_queued_users
#
#  id           :bigint(8)        not null, primary key
#  uid          :bigint(8)        not null
#  processed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_twitter_db_queued_users_on_created_at  (created_at)
#  index_twitter_db_queued_users_on_uid         (uid) UNIQUE
#
class TwitterDB::QueuedUser < ApplicationRecord
  IMPORT_COLUMNS = %i(uid processed_at created_at updated_at)

  class << self
    def import_data(uids)
      time = Time.zone.now
      data = uids.map { |uid| [uid, time, time, time] }
      import IMPORT_COLUMNS, data, on_duplicate_key_update: %i(uid updated_at), validate: false, timestamps: false
    end
  end
end
