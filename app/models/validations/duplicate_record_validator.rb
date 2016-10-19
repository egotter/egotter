module Validations
  class DuplicateRecordValidator < ActiveModel::Validator
    def validate(record)
      fresh_record_exists?(record)
      same_record_exists?(record)
    end

    private

    def fresh_record_exists?(record)
      latest = TwitterUser.latest(record.uid.to_i)
      return false if latest.nil?

      if latest.fresh?
        record.errors[:base] << "[#{latest.id}] is recently created."
        return true
      end

      false
    end

    def same_record_exists?(record)
      latest = TwitterUser.latest(record.uid.to_i)
      return false if latest.nil?
      same_record?(latest, record)
    end

    def same_record?(older, newer)
      return false if older.nil?
      return false if older.diff(newer).any?

      newer.errors[:base] << "[#{older.id}] is not changed."
      true
    end
  end
end