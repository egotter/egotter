module UsersHelper
  def current_user_friend_uids
    if instance_variable_defined?(:@current_user_friend_uids)
      @current_user_friend_uids
    else
      return (@current_user_friend_uids = []) unless user_signed_in?

      twitter_user = TwitterUser.where('friends_count < 5000').latest_by(uid: current_user.uid)
      return (@current_user_friend_uids = []) unless twitter_user

      @current_user_friend_uids = twitter_user.friend_uids
    end
  end

  def current_user_follower_uids
    if instance_variable_defined?(:@current_user_follower_uids)
      @current_user_follower_uids
    else
      return (@current_user_follower_uids = []) unless user_signed_in?

      # To increase the efficiency of query execution, followers_count is excluded from the query.
      twitter_user = TwitterUser.latest_by(uid: current_user.uid)
      return (@current_user_follower_uids = []) if !twitter_user || twitter_user.followers_count >= 5000

      @current_user_follower_uids = twitter_user.follower_uids
    end
  end

  def current_user_blocking_uids
    user_signed_in? ? BlockingRelationship.where(from_uid: current_user.uid).limit(3000).pluck(:to_uid) : []
  end

  def current_user_icon
    if instance_variable_defined?(:@current_user_icon)
      @current_user_icon
    else
      if user_signed_in?
        url = TwitterDB::User.find_by(uid: current_user.uid)&.profile_image_url_https
      else
        url = egotter_icon_url
      end
      @current_user_icon = url
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
