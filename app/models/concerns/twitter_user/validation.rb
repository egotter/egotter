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
    if uid.present? && uid.match(Validations::UidValidator::REGEXP)
      true
    else
      errors.add(:uid, :invalid)
      false
    end
  end

  def valid_screen_name?
    if screen_name.present? && screen_name.match(Validations::ScreenNameValidator::REGEXP)
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
  def inconsistent_friends?
    return false if zero_friends?

    if friends_count.to_i != friends.size && (friends_count.to_i - friends.size).abs > friends_count.to_i * 0.1
      errors[:base] << "friends_count #{friends_count} doesn't agree with friends.size #{friends.size}."
      return true
    end

    false
  end

  # not using in valid?
  def inconsistent_followers?
    return false if zero_followers?

    if followers_count.to_i != followers.size && (followers_count.to_i - followers.size).abs > followers_count.to_i * 0.1
      errors[:base] << "followers_count #{followers_count} doesn't agree with followers.size #{followers.size}."
      return true
    end

    false
  end

  # not using in valid?
  def zero_friends?
    friends_count.to_i == 0 && friends.size == 0 ? true : false
  end

  # not using in valid?
  def zero_followers?
    followers_count.to_i == 0 && followers.size == 0 ? true : false
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
    if friends_count + followers_count > (login_user.nil? ? MANY_FRIENDS : TOO_MANY_FRIENDS)
      errors[:base] << "too many friends #{friends_count} and followers #{followers_count}"
      return true
    end

    false
  end
end
