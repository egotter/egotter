namespace :egotter_blockers do
  task destroy: :environment do
    uid = ENV['UID']&.to_i
    client = User.egotter_cs.api_client

    unless (user = User.find_by(uid: uid))
      client.create_direct_message(uid, I18n.t('rake_tasks.egotter_blockers.user_not_found_message'))
      puts "User not found uid=#{uid}"
      next
    end

    puts "uid=#{uid} screen_name=#{user.screen_name}"

    unless (record = EgotterBlocker.find_by(uid: user.uid))
      client.create_direct_message(uid, I18n.t('rake_tasks.egotter_blockers.blocker_not_found_message'))
      puts "EgotterBlocker not found uid=#{uid}"
      next
    end

    begin
      user.api_client.twitter.verify_credentials
    rescue => e
      if e.message == 'Invalid or expired token.'
        client.create_direct_message(user.uid, I18n.t('rake_tasks.egotter_blockers.unauthorized_message'))
        puts 'Unauthorized'
        next
      else
        raise
      end
    end

    if user.api_client.twitter.block?(User::EGOTTER_UID)
      client.create_direct_message(user.uid, I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
      puts 'Still blocking'
      next
    end

    unless user.has_valid_subscription?
      client.create_direct_message(user.uid, I18n.t('rake_tasks.egotter_blockers.dont_have_subscription_message'))
      puts "Don't have a subscription"
      next
    end

    begin
      record.destroy!
      client.create_direct_message(user.uid, I18n.t('rake_tasks.egotter_blockers.success_message'))
      puts 'Success'
    rescue => e
      puts e.inspect
    end
  end
end
