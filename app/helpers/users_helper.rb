module UsersHelper
  def current_user_friend_screen_names
    if instance_variable_defined?(:@current_user_friend_screen_names)
      @current_user_friend_screen_names
    else
      return (@current_user_friend_screen_names = []) unless user_signed_in?

      twitter_user = TwitterUser.latest_by(uid: current_user.uid)
      return (@current_user_friend_screen_names = []) unless twitter_user

      @current_user_friend_screen_names = twitter_user.friends.pluck(:screen_name)
    end
  end

  def current_user_friend_screen_names_rendered?
    if instance_variable_defined?(:@current_user_friend_screen_names_rendered)
      @current_user_friend_screen_names_rendered
    else
      @current_user_friend_screen_names_rendered = true
      false
    end
  end
end
