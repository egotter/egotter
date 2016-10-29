module Validations
  class ScreenNameValidator < ActiveModel::Validator
    REGEXP = /\A[a-zA-Z0-9_]{1,20}\z/

    def validate(record)
      if record.screen_name.nil? || !record.screen_name.match(REGEXP)
        record.errors.add(:screen_name, :invalid)
      end
    end
  end
end