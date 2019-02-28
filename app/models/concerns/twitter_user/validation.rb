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
      return false if login_user.present? && t_user[:id] == User::EGOTTER_UID

      if t_user[:friends_count] + t_user[:followers_count] > (login_user.nil? ? MANY_FRIENDS : TOO_MANY_FRIENDS)
        return true
      end

      false
    end
  end

  def valid_uid?
    Validations::UidValidator.new.validate(self)
    self.errors.empty?
  end

  def valid_screen_name?
    Validations::ScreenNameValidator.new.validate(self)
    self.errors.empty?
  end

  def protected_account?
    !!self.protected
  end

  def public_account?
    !protected_account?
  end

  def verified_account?
    !!self.verified
  end

  def readable_by?(login_user)
    login_user.uid.to_i == uid.to_i || login_user.api_client.friendship?(login_user.uid.to_i, uid.to_i)
  end

  def suspended_account?
    !!self.suspended
  end

  # not using in valid?
  def many_friends?
    if friends_count + followers_count > MANY_FRIENDS
      errors[:base] << "many friends #{friends_count} and followers #{followers_count}"
      return true
    end

    false
  end

  # not using in valid?
  def too_many_friends?(login_user:, add_error: true)
    return false if login_user.present? && uid.to_i == User::EGOTTER_UID

    if friends_count + followers_count > (login_user.nil? ? MANY_FRIENDS : TOO_MANY_FRIENDS)
      errors[:base] << "too many friends #{friends_count} and followers #{followers_count}" if add_error
      return true
    end

    false
  end
end
