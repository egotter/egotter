class DestroyBannedUserTask

  def initialize(user, dry_run: false)
    @user = user
    @dry_run = dry_run
  end

  def start
    unless (banned_user = BannedUser.find_by(user_id: @user.id))
      send_dm(I18n.t('rake_tasks.egotter_blockers.banned_user_not_found_message'))
      puts "BannedUser not found user_id=#{@user.id}"
      return
    end

    api_user = nil
    begin
      api_user = @user.api_client.twitter.verify_credentials
    rescue => e
      if TwitterApiStatus.invalid_or_expired_token?(e)
        send_dm(I18n.t('rake_tasks.egotter_blockers.unauthorized_message'))
        puts 'Unauthorized'
        return
      else
        raise
      end
    end

    if api_user.protected
      # Twitter::Error::TooManyRequests: Rate limit exceeded
      if @user.api_client.twitter.block?(User::EGOTTER_UID)
        send_dm(I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
        puts 'Still blocking'
        return
      end
    else
      begin
        User.egotter.api_client.user_timeline(@user.uid)
      rescue => e
        if TwitterApiStatus.blocked?(e)
          send_dm(I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
          puts 'Still blocking'
          return
        else
          raise
        end
      end
    end

    unless @user.has_valid_subscription?
      send_dm(I18n.t('rake_tasks.egotter_blockers.dont_have_subscription_message'))
      puts "Don't have a subscription"
      return
    end

    begin
      banned_user.destroy!
      send_dm(I18n.t('rake_tasks.egotter_blockers.success_message'))
      puts 'Success'
    rescue => e
      puts e.inspect
    end
  end

  private

  def send_dm(message)
    User.egotter_cs.api_client.create_direct_message(@user.uid, message) unless @dry_run
    puts message
  end
end
