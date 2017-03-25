require 'active_support/concern'

module Concerns::TwitterUser::Validation
  extend ActiveSupport::Concern

  MANY_FRIENDS = Rails.configuration.x.constants['many_friends_threshold']
  TOO_MANY_FRIENDS = Rails.configuration.x.constants['too_many_friends_threshold']

  included do
    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator
    # validates_with Validations::UserInfoValidator
    validates_with Validations::FreshRecordValidator, on: :create
    validates_with Validations::DuplicateRecordValidator, on: :create
  end

  def valid_uid?
    if uid&.to_s&.match(Validations::UidValidator::REGEXP)
      true
    else
      errors.add(:uid, :invalid)
      false
    end
  end

  def valid_screen_name?
    if screen_name&.match(Validations::ScreenNameValidator::REGEXP)
      true
    else
      errors.add(:screen_name, :invalid)
      false
    end
  end

  def protected_account?
    !!self.protected
  end

  def public_account?
    !protected_account?
  end

  def forbidden_account?
    ForbiddenUser.exists?(screen_name: screen_name)
  end

  def readable_by?(login_user)
    case
      when login_user.nil? then false
      when login_user.uid.to_i == uid.to_i then true
      when login_user.api_client.friendship?(login_user.uid.to_i, uid.to_i) then true
      else false
    end
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
  def too_many_friends?(login_user:)
    return false if login_user.present? && uid.to_i == User::EGOTTER_UID

    if friends_count + followers_count > (login_user.nil? ? MANY_FRIENDS : TOO_MANY_FRIENDS)
      errors[:base] << "too many friends #{friends_count} and followers #{followers_count}"
      return true
    end

    false
  end
end
