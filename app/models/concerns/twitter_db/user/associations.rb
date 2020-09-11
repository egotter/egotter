require 'active_support/concern'

module Concerns::TwitterDB::User::Associations
  extend ActiveSupport::Concern

  class_methods do
    # TODO Set user_id
    # This method makes the result unique.
    def where_and_order_by_field(uids:, inactive: nil)
      caller_name = (caller[0][/`([^']*)'/, 1] rescue '')

      uids.uniq.each_slice(1000).map do |uids_array|
        where_and_order_by_field_each_slice(uids_array, inactive, caller_name)
      end.flatten
    end

    private

    def where_and_order_by_field_each_slice(uids, inactive, caller_name = nil)
      # result = where(uid: uids_array).sort_by {|user| uids_array.index(user.uid)}

      result = where(uid: uids)
      result = result.inactive_user if !inactive.nil? && inactive
      result = result.order_by_field(uids).to_a

      # if !inactive.nil? && inactive
      #   enqueue_update_job(result.map(&:uid), caller_name)
      # elsif uids.size != result.size
      #   enqueue_update_job(uids - result.map(&:uid), caller_name)
      # end
      enqueue_update_job(uids, caller_name)

      result
    end

    def enqueue_update_job(uids, caller_name = nil)
      CreateTwitterDBUserWorker.compress_and_perform_async(uids, enqueued_by: "##{caller_name} > #where_and_order_by_field")
    end
  end

  included do
    scope :order_by_field, -> (uids) { order(Arel.sql("field(uid, #{uids.join(',')})")) }
  end
end
