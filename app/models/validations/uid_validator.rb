module Validations
  class UidValidator < ActiveModel::Validator
    REGEXP = /\A[1-9][0-9]*\z/

    def validate(record)
      if record.uid.blank?
        record.errors.add(:uid, :blank)
      elsif !record.uid.to_s.match(REGEXP)
        record.errors.add(:uid, :invalid)
      end
    end
  end
end