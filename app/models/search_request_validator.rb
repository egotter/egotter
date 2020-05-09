class SearchRequestValidator
  def initialize(user)
    @user = user
  end

  def user_requested_self_search?(screen_name)
    client.user(screen_name)[:id] == @user.uid
  rescue => e
    false
  end

  def not_found_user?(screen_name)
    client.user(screen_name)
    DeleteNotFoundUserWorker.perform_async(screen_name)
    false
  rescue => e
    if AccountStatus.not_found?(e)
      CreateNotFoundUserWorker.perform_async(screen_name)
      true
    else
      false
    end
  end

  def forbidden_user?(screen_name)
    client.user(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)
    false
  rescue => e
    if AccountStatus.suspended?(e)
      CreateForbiddenUserWorker.perform_async(screen_name)
      true
    else
      false
    end
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
