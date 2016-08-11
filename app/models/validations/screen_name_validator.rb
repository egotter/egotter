module Validations
  class ScreenNameValidator < ActiveModel::Validator
    SCREEN_NAME_REGEXP = /\A[a-zA-Z0-9_]{1,20}\z/

    def validate(record)
      if record.screen_name.nil? || !record.screen_name.match(SCREEN_NAME_REGEXP)
        record.errors.add(:screen_name, :invalid)
      end
    end
  end
end