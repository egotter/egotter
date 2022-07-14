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
  validates :uid, presence: true, uniqueness: true

  IMPORT_COLUMNS = %i(uid created_at updated_at)

  class << self
    def import_data(uids)
      return if uids.empty?
      time = Time.zone.now
      data = uids.map { |uid| [uid, time, time] }
      import IMPORT_COLUMNS, data, on_duplicate_key_update: %i(uid updated_at), validate: false, timestamps: false
    rescue ActiveRecord::Deadlocked, ActiveRecord::StatementInvalid => e
      Airbag.info "TwitterDB::QueuedUser#import_data #{e.inspect.truncate(200)}"
      handle_deadlock(uids)
    end

    def handle_deadlock(uids)
      uids.each do |uid|
        create!(uid: uid)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => ee
        Airbag.info "TwitterDB::QueuedUser#handle_deadlock #{ee.inspect.truncate(200)}"
      end
    end

    def delete_stale_records
      query = select(:id).where('created_at < ?', 6.hours.ago)

      processed_ids = query.where.not(processed_at: nil).find_in_batches.map do |records|
        records.map(&:id)
      end.flatten

      unprocessed_ids = query.where(processed_at: nil).find_in_batches.map do |records|
        records.map(&:id)
      end.flatten

      (processed_ids + unprocessed_ids).each_slice(1000) do |ids|
        where(id: ids).delete_all
      end
    end
  end
end
