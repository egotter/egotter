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
      overwrite = ENV['OVERWRITE'] ? true : false

      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'] : 1
      process_start = Time.zone.now
      failed = false
      puts "\ncopy started:"

      Rails.logger.silence do
        klass.find_in_batches(start: start, batch_size: 5000) do |users_array|
          users = users_array.map do |u|
            [u.uid, u.screen_name, u.user_info] # TODO timestamps
          end

          options = {validate: false}
          options.merge!(on_duplicate_key_update: %i(screen_name user_info)) if overwrite
          begin
            TwitterDB::User.import(%i(uid screen_name user_info), users, options)
            puts "#{Time.zone.now}: #{users_array[0].id} - #{users_array[-1].id}"
          rescue => e
            puts "#{e.class} #{e.message.slice(0, 100)}"
            failed = true
          end
          break if sigint || failed
        end
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
      Rails.logger.silence do
        TwitterUser.includes(:friends, :followers).with_friends.order(created_at: :desc).find_in_batches(start: start, batch_size: 100) do |twitter_users|
          targets = twitter_users.select { |tu| processed.exclude?(tu.uid.to_i) }
          users = TwitterDB::User.includes(:friends, :followers).where(uid: targets.map(&:uid)).index_by { |u| u.uid.to_i }

          targets.each do |twitter_user|
            user = users[twitter_user.uid.to_i]

            if %i(friends followers).all? { |relation| twitter_user.send(relation).map(&:uid).map(&:to_i).sort == user.send(relation).map(&:uid).map(&:to_i).sort }
              puts "skip #{twitter_user.uid} #{twitter_user.screen_name}"
              processed << twitter_user.uid.to_i
              next
            end

            friendships = twitter_user.friends.map { |f| [f.uid, user.uid] }
            followerships = twitter_user.followers.map { |f| [f.uid, user.uid] }

            begin
              ActiveRecord::Base.transaction do
                if user.friends.any? || user.followers.any?
                  TwitterDB::Friendship.delete_all(user_uid: twitter_user.uid)
                  TwitterDB::Followership.delete_all(user_uid: twitter_user.uid)
                  puts "overwrite #{twitter_user.uid} #{twitter_user.screen_name}"
                end

                TwitterDB::Friendship.import(%i(friend_uid user_uid), friendships, validate: false, timestamps: false)
                TwitterDB::Followership.import(%i(follower_uid user_uid), followerships, validate: false, timestamps: false)
                user.tap do |u|
                  u.assign_attributes(friends_size: friendships.size, followers_size: followerships.size)
                  u.save! if u.changed?
                end
              end

              user.reload
            rescue => e
              puts "#{user.uid} #{user.screen_name} #{e.class} #{e.message}"
              failed = true
            end
            break if sigint || failed

            processed << twitter_user.uid.to_i
          end

          puts "#{Time.zone.now}: size: #{twitter_users.size}, targets: #{targets.size}, #{twitter_users.first.id} - #{twitter_users.last.id}"
        end
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end
