require 'active_support/concern'

module Concerns::TwitterUser::Validation
  extend ActiveSupport::Concern

  MANY_FRIENDS = Rails.configuration.x.constants['many_friends_threshold']
  TOO_MANY_FRIENDS = Rails.configuration.x.constants['too_many_friends_threshold']

  included do
    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    validates_with Validations::RawAttrsTextValidator, on: :create
    validates_with Validations::FreshRecordValidator, on: :create
    validates_with Validations::DuplicateRecordValidator, on: :create
  end

  class_methods do
    def too_many_friends?(t_user, login_user:)
      return false if t_user[:id] == User::EGOTTER_UID

      if t_user[:friends_count] + t_user[:followers_count] > TOO_MANY_FRIENDS
        return true
      end

      false
    end
  end

  def protected_account?
    !!self.protected
  end

  # not using in valid?
  def too_many_friends?(login_user:, add_error: true)
    return false if uid == User::EGOTTER_UID

    if friends_count + followers_count > TOO_MANY_FRIENDS
      errors[:base] << "too many friends #{friends_count} and followers #{followers_count}" if add_error
      return true
    end

    false
  end
end
