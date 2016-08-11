module Validations
  class UserInfoValidator < ActiveModel::Validator
    USER_INFO_REGEXP = /\A\{.*\}\z/

    def validate(record)
      if record.user_info.nil? || !record.user_info.match(USER_INFO_REGEXP)
        record.errors.add(:user_info, :invalid)
      end
    end
  end
end