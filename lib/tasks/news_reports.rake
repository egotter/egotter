namespace :news_reports do
  desc 'send'
  task send: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    user_ids =
      if ENV['USER_IDS']
        ENV['USER_IDS'].remove(' ').split(',').map(&:to_i)
      else
        User.active(30).inactive(14).can_send_dm.pluck(:id)
      end

    # user_ids = User.can_send_news.where(id: user_ids).pluck(:id)
    user_ids = user_ids.select { |id| id > 110981 }

    processed = 0
    failed = false
    reports_count = NewsReport.all.size

    user_ids.each.with_index do |user_id, i|
      user = User.find(user_id)
      twitter_user = user.twitter_user

      unless twitter_user
        puts "No TwitterUser #{user_id}"
        next
      end

      if twitter_user.unfollowerships.empty?
        puts "Empty #{user_id}"
        next
      end

      report = NewsReport.new(user_id: user.id, token: NewsReport.generate_token)
      dm = nil

      begin
        dm = user.api_client.create_direct_message(user.uid.to_i, report.build_message)
      rescue => e
        if e.message == 'Invalid or expired token.'
          user&.update(authorized: false)
          puts "Invalid token #{user_id}"
          next
        elsif e.message == 'Your account is suspended and is not permitted to access this feature.'
          puts "Suspended #{user_id}"
          next
        elsif e.message.start_with? 'To protect our users from spam and other malicious activity,'
          puts "Temporarily locked #{user_id}"
          next
        else
          puts "#{e.class} #{e.message.truncate(100)} #{user_id}"
          failed = true
        end
      end

      if dm
        begin
          ActiveRecord::Base.transaction do
            report.update!(message_id: dm.id)
            user.notification_setting.update!(last_news_at: Time.zone.now)
          end
        rescue => e
          puts "#{e.class}: #{e.message.truncate(100)} #{user_id}"
          failed = true
        end
      end

      processed += 1

      break if sigint || failed
    end

    puts "\n#{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts %Q(  user_ids: #{user_ids.size}, processed: #{processed}, send: #{NewsReport.all.size - reports_count}\n\n)
  end
end
