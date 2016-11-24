namespace :twitter do
  desc 'cleanup'
  task cleanup: :environment do
    Twitter::REST::Client.new.cache.cleanup
  end

  namespace :db do
    desc 'create'
    task create: :environment do
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE DATABASE /*!32312 IF NOT EXISTS*/ `twitter` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */
      SQL
    end

    desc 'copy users'
    task copy_users: :environment do
      klass = ENV['TABLE'].classify.constantize

      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'] : 1
      process_start = Time.zone.now
      failed = false
      puts "\ncopy started:"

      klass.find_in_batches(start: start, batch_size: 5000) do |users_array|
        users = users_array.map do |u|
          [u.uid, u.screen_name, u.user_info]
        end

        begin
          TwitterDB::User.import(%i(uid screen_name user_info), users, on_duplicate_key_update: %i(screen_name user_info), validate: false)
          puts "#{Time.zone.now}: #{users_array[0].id} - #{users_array[-1].id}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end
        break if sigint || failed
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end

    desc 'copy_relations'
    task copy_relations: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'] : 1
      process_start = Time.zone.now
      failed = false
      puts "\ncopy started:"

      processed = []
      TwitterUser.includes(:friends, :followers).with_friends.order(created_at: :desc).find_each(start: start, batch_size: 100) do |twitter_user|
        next if processed.include? twitter_user.uid

        user = TwitterDB::User.find(twitter_user.uid)

        begin
          ActiveRecord::Base.transaction do
            user.friend_uids = twitter_user.friends.map(&:uid)
            user.follower_uids = twitter_user.followers.map(&:uid)
            user.update!(friends_size: user.friends.size, followers_size: user.followers.size)
          end
          puts "#{Time.zone.now}: #{twitter_users.first.id} - #{twitter_users.last.id}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end
        break if sigint || failed

        processed << twitter_user.uid
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end
