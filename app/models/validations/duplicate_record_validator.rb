module Validations
  class DuplicateRecordValidator < ActiveModel::Validator
    def validate(new_record)
      record = TwitterUser.with_friends.latest(new_record.uid.to_i)
      return if record.nil? || record.diff(new_record).any?

      new_record.errors[:base] << "[#{record.id}] is not changed."
    end
  end
end
