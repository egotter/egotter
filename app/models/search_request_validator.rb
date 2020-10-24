class SearchRequestValidator
  def initialize(client, user)
    @client = client
    @user = user
  end

  def search_for_yourself?(screen_name)
    user_signed_in? && @user.uid == @client.user(screen_name)[:id]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    false
  end

  def user_requested_self_search_by_uid?(uid)
    user_signed_in? && @user.uid == uid.to_i
  end

  def not_found_user?(screen_name)
    @client.user(screen_name)
    false
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.not_found?(e)
  end

  def forbidden_user?(screen_name)
    @client.user(screen_name)[:suspended]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.suspended?(e)
  end

  def blocked_user?(screen_name)
    if user_signed_in?
      @client.user_timeline(screen_name, count: 1)
      false
    else
      false
    end
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.blocked?(e)
  end

  def protected_user?(screen_name)
    @client.user(screen_name)[:protected]
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    TwitterApiStatus.protected?(e)
  end

  def timeline_readable?(screen_name)
    @client.user_timeline(screen_name, count: 1)
  rescue => e
    logger.debug { "#{self.class}##{__method__} #{e.inspect} screen_name=#{screen_name}" }
    !TwitterApiStatus.protected?(e)
  end

  private

  def user_signed_in?
    @user
  end

  def logger
    Rails.logger
  end
end
