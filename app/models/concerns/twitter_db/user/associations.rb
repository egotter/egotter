require 'active_support/concern'

module Concerns::TwitterDB::User::Associations
  extend ActiveSupport::Concern

  class_methods do
    # This method makes the result unique.
    def where_and_order_by_field(uids:)
      uids.uniq.each_slice(1000).map do |uids_array|
        where_and_order_by_field_each_slice(uids_array)
      end.flatten
    end

    def where_and_order_by_field_each_slice(uids)
      # result = where(uid: uids_array).sort_by {|user| uids_array.index(user.uid)}
      result = where(uid: uids).order_by_field(uids).to_a

      unless uids.size == result.size
        enqueue_update_job(uids - result.map(&:uid))
      end

      result
    end

    def order_by_field(uids)
      order(Arel.sql("field(uid, #{uids.join(',')})"))
    end

    def enqueue_update_job(uids)
      uids.each_slice(100) do |uids_array|
        CreateTwitterDBUserWorker.perform_async(uids_array, enqueued_by: 'where_and_order_by_field')
      end
    end
  end

  included do
    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> { order(sequence: :asc) }

    with_options default_options.merge(primary_key: :uid, foreign_key: :from_uid) do |obj|
      obj.has_many :unfriendships,     order_by_sequence_asc
      obj.has_many :unfollowerships,   order_by_sequence_asc
      obj.has_many :block_friendships, order_by_sequence_asc
    end

    with_options default_options.merge(class_name: 'TwitterDB::User') do |obj|
      obj.has_many :unfriends,     through: :unfriendships
      obj.has_many :unfollowers,   through: :unfollowerships
      obj.has_many :block_friends, through: :block_friendships
    end
  end
end
