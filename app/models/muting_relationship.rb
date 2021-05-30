# == Schema Information
#
# Table name: muting_relationships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  to_uid     :bigint(8)        not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_muting_relationships_on_created_at           (created_at)
#  index_muting_relationships_on_from_uid_and_to_uid  (from_uid,to_uid) UNIQUE
#  index_muting_relationships_on_to_uid_and_from_uid  (to_uid,from_uid) UNIQUE
#
class MutingRelationship < ApplicationRecord
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

      uids = collect_with_cursor do |options|
        client.muted_ids(options)
      rescue => e
        unless TwitterApiStatus.invalid_or_expired_token?(e) || TwitterApiStatus.temporarily_locked?(e)
          logger.warn "#{self}##{__method__}: #{e.inspect} user_id=#{user_id}"
        end
        nil
      end

      if uids.size != uids.uniq.size
        logger.warn "#{self}##{__method__}: uids is not unique"
        uids.uniq!
      end

      uids
    end

    def collect_with_cursor(&block)
      options = {count: 5000, cursor: -1}
      collection = []

      12.times do
        response = yield(options)
        break if response.nil?

        collection.concat(response.attrs[:ids])

        if response.attrs[:next_cursor] == 0
          break
        end

        options[:cursor] = response.attrs[:next_cursor]
      end

      collection
    end
  end
end
