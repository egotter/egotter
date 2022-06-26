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
  validates :from_uid, presence: true
  validates :to_uid, presence: true

  class << self
    def update_all_mutes(user)
      uids = collect_uids(user.id)
      return [] if uids.blank?

      additional_uids = filter_additional_mutes(user.uid, uids)
      import_mutes(user.uid, additional_uids)
      Airbag.info { "#{self}: Import #{additional_uids.size} mutes" }

      deletable_uids = filter_deletable_mutes(user.uid, uids)
      delete_mutes(user.uid, deletable_uids)
      Airbag.info { "#{self}: Delete #{deletable_uids.size} mutes" }

      additional_uids
    end

    def import_mutes(from_uid, to_uids)
      to_uids.each_slice(1000) do |uids_array|
        time = Time.zone.now
        if where(from_uid: from_uid, to_uid: uids_array).size != uids_array.size
          data = uids_array.map { |to_uid| [from_uid, to_uid, time] }
          import %i(from_uid to_uid created_at), data, on_duplicate_key_update: %i(from_uid to_uid created_at), validate: false, timestamps: false
        end
      end
    end

    def filter_additional_mutes(from_uid, to_uids)
      to_uids - where(from_uid: from_uid).pluck(:to_uid)
    end

    def filter_deletable_mutes(from_uid, to_uids)
      where(from_uid: from_uid).pluck(:to_uid) - to_uids
    end

    def delete_mutes(from_uid, to_uids)
      to_uids.each_slice(1000) do |uids_array|
        where(from_uid: from_uid, to_uid: uids_array).delete_all
      end

    end

    # TODO Remove later
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
        if TwitterApiStatus.invalid_or_expired_token?(e) || TwitterApiStatus.temporarily_locked?(e)
          # Do nothing
        else
          Airbag.warn "#{self}##{__method__}: #{e.inspect} user_id=#{user_id}"
        end
        nil
      end

      if uids.size != uids.uniq.size
        Airbag.warn "#{self}##{__method__}: uids is not unique user_id=#{user_id}"
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
