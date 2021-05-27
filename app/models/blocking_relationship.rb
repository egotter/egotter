# == Schema Information
#
# Table name: blocking_relationships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  to_uid     :bigint(8)        not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_blocking_relationships_on_created_at           (created_at)
#  index_blocking_relationships_on_from_uid_and_to_uid  (from_uid,to_uid) UNIQUE
#  index_blocking_relationships_on_to_uid_and_from_uid  (to_uid,from_uid) UNIQUE
#
class BlockingRelationship < ApplicationRecord
  class << self
    def import_from(from_uid, to_uids)
      values = to_uids.map { |to_uid| [from_uid, to_uid] }

      transaction do
        where(from_uid: from_uid).delete_all if exists?(from_uid: from_uid)
        Rails.logger.silence { import([:from_uid, :to_uid], values, validate: false) }
      end
    end

    def collect_uids(user_id)
      client = User.find(user_id).api_client.twitter
      options = {count: 5000, cursor: -1}
      call_limit = 12
      call_count = 0
      collection = []

      while true do
        response = nil
        begin
          response = client.blocked_ids(options)
        rescue => e
        end

        call_count += 1
        break if response.nil?

        collection.concat(response.attrs[:ids])

        if response.attrs[:next_cursor] == 0 || call_count >= call_limit
          break
        end

        options[:cursor] = response.attrs[:next_cursor]
      end

      if collection.size != collection.uniq.size
        logger.warn "#{__method__}: uids is not unique"
        collection.uniq!
      end

      collection
    end
  end
end
