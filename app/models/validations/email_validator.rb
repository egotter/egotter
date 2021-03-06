module Validations
  class EmailValidator < ActiveModel::Validator
    REGEXP = /\A[^@]+@[^@]+\z/

    def validate(record)
      if record.email.nil?
        record.errors.add(:email, :blank)
      elsif record.email == ''
      elsif !record.email.to_s.match(REGEXP)
        record.errors.add(:email, :invalid)
      end
    end
  end
end