module Validations
  class FreshRecordValidator < ActiveModel::Validator
    def validate(new_record)
      latest = TwitterUser.latest(new_record.uid.to_i)
      return if latest.nil?

      if latest.fresh?
        new_record.errors[:base] << "[#{latest.id}] is recently updated."
      end
    end
  end
end
