module Validations
  class UserInfoValidator < ActiveModel::Validator
    REGEXP = /\A\{.*\}\z/

    def validate(record)
      if record.user_info.blank?
        record.errors.add(:user_info, :blank)
      elsif !record.user_info.match(REGEXP)
        record.errors.add(:user_info, :invalid)
      end
    end
  end
end