module Validations
  class ScreenNameValidator < ActiveModel::Validator
    REGEXP = /\A[a-zA-Z0-9_]{1,20}\z/

    def validate(record)
      if record.screen_name.blank?
        record.errors.add(:screen_name, :blank)
      elsif !record.screen_name.to_s.match(REGEXP)
        record.errors.add(:screen_name, :invalid)
      end
    end
  end
end