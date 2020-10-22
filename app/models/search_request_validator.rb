class SearchRequestValidator
  def initialize(user)
    @user = user
  end

  def user_requested_self_search?(screen_name)
    user_signed_in? && @user.uid == client.user(screen_name)[:id]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    false
  end

  def user_requested_self_search_by_uid?(uid)
    user_signed_in? && @user.uid == uid.to_i
  end

  def not_found_user?(screen_name)
    client.user(screen_name)
    false
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    if TwitterApiStatus.not_found?(e)
      true
    else
      false
    end
  end

  def forbidden_user?(screen_name)
    user = client.user(screen_name)
    user[:suspended]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    if TwitterApiStatus.suspended?(e)
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
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.blocked?(e)
  end

  def protected_user?(screen_name)
    user = client.user(screen_name)
    user[:protected]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.protected?(e)
  end

  def timeline_readable?(screen_name)
    client.user_timeline(screen_name, count: 1)
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    !TwitterApiStatus.protected?(e)
  end

  private

  def user_signed_in?
    @user
  end

  def client
    @client ||= (@user ? @user.api_client : Bot.api_client)
  end

  def logger
    Rails.logger
  end
end
