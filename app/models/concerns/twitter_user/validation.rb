require 'active_support/concern'

module Concerns::TwitterUser::Validation
  extend ActiveSupport::Concern

  included do
    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    validates_with Validations::RawAttrsTextValidator, on: :create
    validates_with Validations::FreshRecordValidator, on: :create
    validates_with Validations::DuplicateRecordValidator, on: :create
  end

  def protected_account?
    !!self.protected
  end
end
