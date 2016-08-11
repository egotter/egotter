module Validations
  class DuplicateRecordValidator < ActiveModel::Validator
    def validate(record)
      recently_created_record_exists?(record)
      same_record_exists?(record)
    end

    private

    def recently_created_record_exists?(record)
      latest = record.latest

      return false if latest.nil?

      if latest.recently_created? || latest.recently_updated?
        record.errors[:base] << 'A recently created record exists.'
        return true
      end

      false
    end

    def same_record_exists?(record)
      latest = record.latest
      return false if latest.nil?
      same_record?(latest, record)
    end

    def same_record?(older, newer)
      return false if older.nil?

      diff = older.diff(newer)

      # debug code
      # logger.warn older.id
      # logger.warn newer.id
      # logger.warn diff.select { |_, v| v[0] != v[1] }.keys.inspect
      # logger.warn diff.select { |_, v| v[0] != v[1] }.values.inspect

      return false if diff.any? { |_, v| v[0] != v[1] }

      newer.errors[:base] << "Same record(#{newer.id}) exists."
      true
    end
  end
end