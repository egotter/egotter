module UsersHelper
  def current_user_friend_screen_names
    if instance_variable_defined?(:@current_user_friend_screen_names)
      @current_user_friend_screen_names
    else
      return (@current_user_friend_screen_names = []) unless user_signed_in?

      twitter_user = TwitterUser.latest_by(uid: current_user.uid)
      return (@current_user_friend_screen_names = []) unless twitter_user

      @current_user_friend_screen_names = (twitter_user.friends_count < 300) ? twitter_user.friends.pluck(:screen_name) : []
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

  def current_user_follower_uids
    if instance_variable_defined?(:@current_user_follower_uids)
      @current_user_follower_uids
    else
      return (@current_user_follower_uids = []) unless user_signed_in?

      twitter_user = TwitterUser.where('followers_count < 5000').latest_by(uid: current_user.uid)
      return (@current_user_follower_uids = []) unless twitter_user

      @current_user_follower_uids = twitter_user.follower_uids
    end
  end

  def current_user_icon
    if instance_variable_defined?(:@current_user_icon)
      @current_user_icon
    else
      @current_user_icon = TwitterDB::User.find_by(uid: current_user&.uid)&.profile_image_url_https
    end
  end

  def current_user_statuses_count
    if instance_variable_defined?(:@current_user_statuses_count)
      @current_user_statuses_count
    else
      @current_user_statuses_count = current_user&.persisted_statuses_count
    end
  end
end
