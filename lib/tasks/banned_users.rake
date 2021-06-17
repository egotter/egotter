namespace :banned_users do
  task destroy: :environment do
    uid = ENV['UID']&.to_i
    dry_run = ENV['DRY_RUN']

    send_dm = lambda do |message|
      User.egotter_cs.api_client.create_direct_message(uid, message) unless dry_run
      puts message
    end

    unless (user = User.find_by(uid: uid))
      send_dm.call(I18n.t('rake_tasks.egotter_blockers.user_not_found_message'))
      puts "User not found uid=#{uid}"
      next
    end

    puts "uid=#{uid} screen_name=#{user.screen_name}"

    unless (banned_user = BannedUser.find_by(user_id: user.id))
      send_dm.call(I18n.t('rake_tasks.egotter_blockers.banned_user_not_found_message'))
      puts "BannedUser not found user_id=#{user.id}"
      next
    end

    api_user = nil
    begin
      api_user = user.api_client.twitter.verify_credentials
    rescue => e
      if TwitterApiStatus.invalid_or_expired_token?(e)
        send_dm.call(I18n.t('rake_tasks.egotter_blockers.unauthorized_message'))
        puts 'Unauthorized'
        next
      else
        raise
      end
    end

    if api_user[:protected]
      # Twitter::Error::TooManyRequests: Rate limit exceeded
      if user.api_client.twitter.block?(User::EGOTTER_UID)
        send_dm.call(I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
        puts 'Still blocking'
        next
      end
    else
      begin
        User.egotter.api_client.user_timeline(user.uid)
      rescue => e
        if TwitterApiStatus.blocked?(e)
          send_dm.call(I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
          puts 'Still blocking'
          next
        else
          raise
        end
      end
    end

    unless user.has_valid_subscription?
      send_dm.call(I18n.t('rake_tasks.egotter_blockers.dont_have_subscription_message'))
      puts "Don't have a subscription"
      next
    end

    begin
      banned_user.destroy!
      send_dm.call(I18n.t('rake_tasks.egotter_blockers.success_message'))
      puts 'Success'
    rescue => e
      puts e.inspect
    end
  end
end
