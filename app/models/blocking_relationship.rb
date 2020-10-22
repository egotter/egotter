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
  end
end
