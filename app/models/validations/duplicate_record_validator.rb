module Validations
  class DuplicateRecordValidator < ActiveModel::Validator
    def validate(new_record)
      latest = TwitterUser.latest_by(uid: new_record.uid)
      return if latest.nil? || latest.diff(new_record).any?

      new_record.errors[:base] << "id=#{latest.id} is not changed"
    end
  end
end
