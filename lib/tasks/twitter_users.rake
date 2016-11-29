namespace :twitter_users do
  desc 'add user_info'
  task add_user_info: :environment do
    ActiveRecord::Base.connection.execute('ALTER TABLE twitter_users ADD user_info TEXT NOT NULL AFTER user_info_gzip')
  end

  desc 'copy to user_info'
  task copy_to_user_info: :environment do
    Rails.logger.silence do
      TwitterUser.find_each(batch_size: 1000) do |tu|
        tu.update!(user_info: ActiveSupport::Gzip.decompress(tu.user_info_gzip))
      end
    end
  end

  desc 'verify user_info'
  task verify_user_info: :environment do
    TwitterUser.find_each(batch_size: 1000) do |tu|
      unless tu.user_info == ActiveSupport::Gzip.decompress(tu.user_info_gzip)
        puts "id: #{tu.id} doesn't match."
      end
    end
  end

  desc 'drop user_info_gzip'
  task drop_user_info_gzip: :environment do
    ActiveRecord::Base.connection.execute("ALTER TABLE twitter_users DROP user_info_gzip")
  end

  desc 'send prompt reports'
  task send_prompt_reports: :environment do
    ::Tasks::PromptReportsTask.invoke(ENV['USER_IDS'], 'cli', deadline: ENV['DEADLINE'])
  end

  desc 'send update notifications'
  task send_update_notifications: :environment do
    ::Tasks::UpdateNotificationsTask.invoke(ENV['USER_IDS'], 'cli', deadline: ENV['DEADLINE'])
  end

  desc 'fix counts'
  task fix_counts: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    start_time = Time.zone.now
    failed = false
    puts "\nfix counts started:"

    Rails.logger.silence do
      TwitterUser.find_in_batches(start: start, batch_size: 5000) do |array|
        twitter_users = array.map do |tu|
          [tu.id, 0, '', '', tu.friends.size, tu.followers.size, 0, start_time, start_time]
        end

        begin
          TwitterUser.import(%i(id uid screen_name user_info friends_size followers_size user_id created_at updated_at), twitter_users,
                       validate: false, timestamps: false, on_duplicate_key_update: %i(friends_size followers_size))
          puts "#{Time.zone.now}: #{twitter_users.first[0]} - #{twitter_users.last[0]}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end

        break if sigint || failed
      end
    end

    puts "fix counts #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, total: #{(Time.zone.now - start_time).round(1)} seconds"
  end
end
