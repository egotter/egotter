module Validations
  class FreshRecordValidator < ActiveModel::Validator
    def validate(new_record)
      record = TwitterUser.with_friends.latest(new_record.uid.to_i)
      return if record.nil?

      if record.fresh?
        new_record.errors[:base] << "[#{record.id}] is recently updated."
      end
    end
  end
end
