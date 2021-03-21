namespace :egotter_blockers do
  task destroy: :environment do
    uid = ENV['UID']

    unless (user = User.find_by(uid: uid))
      puts "User not found uid=#{uid}"
      next
    end

    puts "uid=#{uid} screen_name=#{user.screen_name}"

    unless (record = EgotterBlocker.find_by(uid: user.uid))
      puts "EgotterBlocker not found uid=#{uid}"
      next
    end

    begin
      user.api_client.twitter.verify_credentials
    rescue => e
      if e.message == 'Invalid or expired token.'
        User.egotter_cs.api_client.create_direct_message_event(user.uid, I18n.t('rake_tasks.egotter_blockers.unauthorized_message'))
        next
      else
        raise
      end
    end

    if user.api_client.twitter.block?(User::EGOTTER_UID)
      User.egotter_cs.api_client.create_direct_message_event(user.uid, I18n.t('rake_tasks.egotter_blockers.still_blocking_message'))
      puts 'Still blocking'
      next
    end

    unless user.has_valid_subscription?
      User.egotter_cs.api_client.create_direct_message_event(user.uid, I18n.t('rake_tasks.egotter_blockers.dont_have_subscription_message'))
      puts "Don't have a subscription"
      next
    end

    begin
      record.destroy!
      User.egotter_cs.api_client.create_direct_message_event(user.uid, I18n.t('rake_tasks.egotter_blockers.success_message'))
      puts 'Success'
    rescue => e
      puts e.inspect
    end
  end
end
