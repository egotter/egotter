module UsersHelper
  def current_user_id
    @current_user_id ||= user_signed_in? ? current_user.id : -1
  end

  def current_user_uid
    @current_user_uid ||= user_signed_in? ? current_user.uid.to_i : -1
  end

  def current_user_friend_uids
    if instance_variable_defined?(:@current_user_friend_uids)
      @current_user_friend_uids
    else
      @current_user_friend_uids = (current_user&.twitter_user&.friend_uids || [])
    end
  end

  def current_user_is_following?(uid)
    current_user_friend_uids.include? uid.to_i
  end

  def current_user_friend_screen_names
    if instance_variable_defined?(:@current_user_friend_screen_names)
      @current_user_friend_screen_names
    else
      @current_user_friend_screen_names = (current_user&.twitter_user&.friends&.pluck(:screen_name) || [])
    end
  end

  def admin_signed_in?
    user_signed_in? && current_user.admin?
  end
end
