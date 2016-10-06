module Validations
  class UidValidator < ActiveModel::Validator
    UID_REGEXP = /\A[1-9][0-9]+\z/

    def validate(record)
      if record.uid.nil? || !record.uid.match(UID_REGEXP)
        record.errors.add(:uid, :invalid)
      end
    end
  end
end