module Validations
  class ProfileTextValidator < ActiveModel::Validator
    REGEXP = /\A\{.*\}\z/

    def validate(record)
      if record.profile_text.blank?
        record.errors.add(:profile_text, :blank)
      elsif !record.profile_text.match(REGEXP)
        record.errors.add(:profile_text, :invalid)
      end
    end
  end
end