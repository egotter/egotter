require 'active_support/concern'

module TwitterUserValidation
  extend ActiveSupport::Concern

  included do
    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    validates_with Validations::ProfileTextValidator, on: :create
    validates_with Validations::FreshRecordValidator, on: :create
  end

  def protected_account?
    !!self.protected
  end
end
