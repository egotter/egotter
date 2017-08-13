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

    processed = 0
    failed = false
    reports_count = NewsReport.all.size

    user_ids.each.with_index do |user_id, i|
      user = User.find(user_id)
      twitter_user = user.twitter_user

      if twitter_user.unfollowerships.empty?
        puts "Skipped #{user_id}"
        next
      end

      report = NewsReport.new(user_id: user.id, token: NewsReport.generate_token)
      dm = nil

      begin
        dm = user.api_client.create_direct_message(user.uid.to_i, report.build_message)
      rescue => e
        puts "#{e.class} #{e.message.truncate(100)} #{user_id}"
        failed = true
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
