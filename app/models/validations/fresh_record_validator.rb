module Validations
  class FreshRecordValidator < ActiveModel::Validator
    def validate(new_record)
      latest = TwitterUser.latest(new_record.uid.to_i)
      return false if latest.nil?

      if latest.fresh?
        new_record.errors[:base] << "[#{latest.id}] is recently updated."
        return true
      end

      false
    end
  end
end
