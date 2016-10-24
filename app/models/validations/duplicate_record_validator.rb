module Validations
  class DuplicateRecordValidator < ActiveModel::Validator
    def validate(new_record)
      latest = TwitterUser.latest(new_record.uid.to_i)
      return if latest.nil? || latest.diff(new_record).any?

      new_record.errors[:base] << "[#{latest.id}] is not changed."
    end
  end
end
