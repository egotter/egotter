require 'active_support/concern'

module Concerns::TwitterUser::Validation
  extend ActiveSupport::Concern

  MANY_FRIENDS = Rails.configuration.x.constants['many_friends_threshold']
  TOO_MANY_FRIENDS = Rails.configuration.x.constants['too_many_friends_threshold']

  SCREEN_NAME_REGEXP = /\A[a-zA-Z0-9_]{1,20}\z/

  included do
    with_options on: :create do |obj|
      obj.validates :uid, presence: true, numericality: :only_integer
      obj.validates :screen_name, format: {with: SCREEN_NAME_REGEXP}
      obj.validates :user_info, presence: true, format: {with: /\A\{.*\}\z/}
    end
  end

  def valid_screen_name?
    if screen_name.present? && screen_name =~ SCREEN_NAME_REGEXP
      true
    else
      errors[:screen_name] << I18n.t('before_sign_in.invalid_twitter_id')
      false
    end
  end

  def search_with_login?
    !login_user.nil?
  end

  def search_without_login?
    !search_with_login?
  end

  def ego_surfing?
    search_with_login? && uid.to_i == login_user.uid.to_i && egotter_context == 'search'
  end

  def protected_account?
    self.protected
  end

  def public_account?
    !protected_account?
  end

  def unauthorized_search?(twitter_link, sign_in_link)
    return false if public_account?
    return true if search_without_login?

    if ego_surfing? || has_permission_to_search?
      return false
    end

    errors[:base] << I18n.t('before_sign_in.protected_user', user: twitter_link, sign_in_link: sign_in_link)
    true
  end

  def unauthorized_job?
    return false unless protected_account?
    return false if User.exists?(uid: uid.to_i)
    errors[:base] << 'unauthorized worker'
    true
  end

  def has_permission_to_search?
    return false unless search_with_login?
    login_user.api_client.friendship?(login_user.uid.to_i, uid.to_i) ? true : false
  end

  def suspended_account?(twitter_link)
    if suspended
      errors[:base] << I18n.t('before_sign_in.suspended_user', user: twitter_link)
      true
    else
      false
    end
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
  def too_many_friends?
    friends_limit =
      if egotter_context == 'search'
        login_user.nil? ? MANY_FRIENDS : TOO_MANY_FRIENDS
      else
        User.exists?(uid: uid.to_i) ? TOO_MANY_FRIENDS : MANY_FRIENDS
      end

    if friends_count + followers_count > friends_limit
      errors[:base] << "too many friends #{friends_count} and followers #{followers_count}"
      return true
    end

    false
  end

  def recently_created_record_exists?
    me = latest_me
    return false if me.blank?

    if me.recently_created? || me.recently_updated?
      errors[:base] << 'recently created record exists'
      return true
    end

    false
  end

  def same_record_exists?
    same_record?(latest_me)
  end

  def same_record?(latest_tu)
    if latest_tu.blank?
      logger.debug "#{screen_name} latest_tu is blank"
      return false
    end

    raise "uid is different(#{self.uid},#{latest_tu.uid})" if self.uid.to_i != latest_tu.uid.to_i

    if self.friends_count != latest_tu.friends_count
      logger.debug "#{screen_name} friends_count is different(#{self.friends_count}, #{latest_tu.friends_count})"
      return false
    end

    if self.followers_count != latest_tu.followers_count
      logger.debug "#{screen_name} followers_count is different(#{self.followers_count}, #{latest_tu.followers_count})"
      return false
    end

    if self.friend_uids != latest_tu.friend_uids
      logger.debug "#{screen_name} friend_uids is different(#{self.friend_uids}, #{latest_tu.friend_uids})"
      return false
    end

    if self.follower_uids != latest_tu.follower_uids
      logger.debug "#{screen_name} follower_uids is different(#{self.follower_uids}, #{latest_tu.follower_uids})"
      return false
    end

    errors[:base] << "id:#{latest_tu.id} is the same record"
    true
  end
end