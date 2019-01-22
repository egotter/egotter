module TwitterUsersHelper
  def build_twitter_user_by(uid: nil, screen_name: nil)
    return build_twitter_user_by(screen_name: request_context_client.user(uid.to_i)[:screen_name]) if uid

    user = request_context_client.user(screen_name)
    twitter_user = TwitterUser.build_by_user(user)

    DeleteNotFoundUserWorker.perform_async(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)

    twitter_user
  rescue => e
    if e.message == 'User not found.'
      CreateNotFoundUserWorker.perform_async(screen_name)
    elsif e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(screen_name)
    end

    if can_see_forbidden_or_not_found?(screen_name: screen_name)
      TwitterUser.order(created_at: :desc).find_by(screen_name: screen_name)
    else
      twitter_exception_handler(e, screen_name)
    end
  end

  def fetch_twitter_user_from_cache(uid)
    attrs = Util::ValidTwitterUserSet.new(Redis.client).get(uid)
    return nil if attrs.nil?

    TwitterUser.new(
      uid: attrs['uid'],
      screen_name: attrs['screen_name'],
      user_info: attrs['user_info'],
    )
  end

  def save_twitter_user_to_cache(uid, screen_name:, user_info:)
    Util::ValidTwitterUserSet.new(Redis.client).set(
      uid,
      {uid: uid, screen_name: screen_name, user_info: user_info}
    )
  end
end
