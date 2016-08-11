module Validations
  class StatusInfoValidator < ActiveModel::Validator
    STATUS_INFO_REGEXP = /\A\{.*\}\z/

    def validate(record)
      if record.status_info.nil? || !record.status_info.match(STATUS_INFO_REGEXP)
        record.errors.add(:status_info, :invalid)
      end
    end
  end
end