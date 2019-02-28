module Validations
  class RawAttrsTextValidator < ActiveModel::Validator
    REGEXP = /\A\{.*\}\z/

    def validate(record)
      if record.raw_attrs_text.blank?
        record.errors.add(:raw_attrs_text, :blank)
      elsif !record.raw_attrs_text.match(REGEXP)
        record.errors.add(:raw_attrs_text, :invalid)
      end
    end
  end
end