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

  desc 'add an update job'
  task add_update_job: :environment do
    UpdateTwitterUserWorker.perform_async(ENV['USER_ID'].to_i)
  end

  desc 'add update jobs'
  task add_update_jobs: :environment do
    deadline =
      case
        when ENV['DEADLINE'].nil? then nil
        when ENV['DEADLINE'].match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(ENV['DEADLINE'])
        else Time.zone.parse(ENV['DEADLINE'])
      end
    user_ids = ENV['USER_IDS']
    next if user_ids.blank?

    user_ids =
      case
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    start_time = Time.zone.now
    puts "\nstart at #{start_time}"
    puts "finish at #{deadline}" if deadline

    user_ids.each.with_index do |user_id, i|
      start = Time.zone.now
      UpdateTwitterUserWorker.new.perform(user_id)
      avg = i % 10 == 0 ? ", #{'%4.1f' % ((Time.zone.now - start_time) / (i + 1))} seconds/user" : ''
      elapsed = i % 10 == 0 ? ", #{'%.1f' % (Time.zone.now - start_time)} seconds elapsed" : ''
      remaining = i % 10 == 0 ? ", #{'%.1f' % (deadline - Time.zone.now)} seconds remaining" : ''
      puts "#{Time.zone.now}: #{user_id}, #{'%4.1f' % (Time.zone.now - start)} seconds#{avg}#{elapsed}#{remaining}"

      break if deadline && Time.zone.now > deadline
    end
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
