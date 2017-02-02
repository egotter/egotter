namespace :twitter_db do
  desc 'create'
  task create: :environment do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE DATABASE /*!32312 IF NOT EXISTS*/ `twitter_development` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE DATABASE /*!32312 IF NOT EXISTS*/ `twitter_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE DATABASE /*!32312 IF NOT EXISTS*/ `twitter` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */
    SQL
  end

  desc 'copy users'
  task copy_users: :environment do
    klass = ENV['TABLE'].classify.constantize
    interval = ENV['INTERVAL'] ? ENV['INTERVAL'].to_f : nil

    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    failed = false
    puts "\ncopy started:"

    Rails.logger.silence do
      klass.find_in_batches(start: start, batch_size: batch_size) do |users_array|
        begin
          TwitterDB::User.import_from!(users_array)
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end
        break if sigint || failed

        sleep interval if interval
      end
    end

    process_finish = Time.zone.now
    sleeping = interval ? ", interval: #{interval}" : ''
    puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds#{sleeping}"
  end

  desc 'copy_relations'
  task copy_relations: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    failed = false
    puts "\ncopy started:"

    processed = []
    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |targets|
        uids = targets.select { |tu| processed.exclude?(tu.uid.to_i) }.map(&:uid).uniq
        twitter_users = TwitterUser.where(uid: uids).order(created_at: :asc).index_by { |tu| tu.uid.to_i }.values

        twitter_users.each do |twitter_user|
          begin
            ActiveRecord::Base.transaction do
              user = TwitterDB::User.find_or_import_by(twitter_user)
              friend_uids = twitter_user.friendships.pluck(:friend_uid)
              follower_uids = twitter_user.followerships.pluck(:follower_uid)

              TwitterDB::Friendship.import_from!(twitter_user.uid.to_i, friend_uids) if friend_uids.any?
              TwitterDB::Followership.import_from!(twitter_user.uid.to_i, follower_uids) if follower_uids.any?

              user.update_columns(friends_size: friend_uids.size, followers_size: follower_uids.size)
            end
          rescue ActiveRecord::InvalidForeignKey => e
            failed = true
            puts "#{twitter_user.uid} #{twitter_user.screen_name} #{e.class} #{e.message}"
            friend_uids = twitter_user.friends.pluck(:uid).map(&:to_i)
            puts "no friends: #{friend_uids - TwitterDB::User.where(uid: friend_uids).pluck(:uid)}"
            follower_uids = twitter_user.followers.pluck(:uid).map(&:to_i)
            puts "no followers: #{follower_uids - TwitterDB::User.where(uid: follower_uids).pluck(:uid)}"
          rescue => e
            failed = true
            puts "#{twitter_user.uid} #{twitter_user.screen_name} #{e.class} #{e.message}"
          end
          break if sigint || failed

          processed << twitter_user.uid.to_i
        end
        break if sigint || failed

        puts "#{Time.zone.now}: targets: #{targets.size}, uids: #{uids.size}, twitter_users: #{twitter_users.size},  processed: #{processed.size}, #{targets[0].id} - #{targets[-1].id}"
      end
    end

    process_finish = Time.zone.now
    puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end

  desc 'verify_relations'
  task verify_relations: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 100
    process_start = Time.zone.now
    puts "\nverify started:"

    processed = 0
    invalid = []
    Rails.logger.silence do
      TwitterDB::User.where('friends_size >= 0 and followers_size >= 0').find_in_batches(start: start, batch_size: batch_size) do |users_array|
        TwitterDB::User.where(id: users_array.map(&:id)).each do |user|
          friends_size = [
            user.friends.size,
            user.friends_size,
            user.friendships.size,
            TwitterDB::Friendship.where(user_uid: user.uid).size
          ]

          followers_size = [
            user.followers.size,
            user.followers_size,
            user.followerships.size,
            TwitterDB::Followership.where(user_uid: user.uid).size
          ]

          if [friends_size, followers_size].any? { |array| !array.combination(2).all? { |a, b| a == b } }
            invalid << user.id
            puts "invalid id: #{user.id}, uid: #{user.uid}, screen_name: #{user.screen_name}, friends: #{friends_size.inspect}, followers: #{followers_size.inspect}"
          end

          break if sigint
        end
        processed += users_array.size

        avg = '%4.1f' % (1000 * (Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now} processed: #{processed}, avg(1000): #{avg}, #{users_array[0].id} - #{users_array[-1].id}"

        break if sigint
      end
    end

    process_finish = Time.zone.now
    puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    puts "invalid #{invalid.inspect}" if invalid.any?
  end
end
