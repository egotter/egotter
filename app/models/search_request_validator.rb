class SearchRequestValidator
  def initialize(user)
    @user = user
  end

  def blocked_user?(screen_name)
    if user_signed_in?
      client.user_timeline(screen_name, count: 1)
      false
    else
      false
    end
  rescue => e
    AccountStatus.blocked?(e)
  end

  def protected_user?(screen_name)
    if user_signed_in?
      client.user_timeline(screen_name, count: 1)
      false
    else
      user = client.user(screen_name)
      user[:protected]
    end
  rescue => e
    AccountStatus.protected?(e)
  end

  def user_signed_in?
    @user
  end

  def client
    @client ||= (@user ? @user.api_client : Bot.api_client)
  end
end
