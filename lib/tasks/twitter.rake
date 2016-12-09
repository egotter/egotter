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

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      failed = false
      import_columns = %i(uid screen_name friends_size followers_size user_info created_at updated_at)
      update_columns = %i(screen_name user_info updated_at)
      puts "\ncopy started:"

      Rails.logger.silence do
        klass.find_in_batches(start: start, batch_size: batch_size) do |users_array|
          users = users_array.map do |u|
            [u.uid, u.screen_name, -1, -1, u.user_info, u.created_at, u.created_at]
          end

          begin
            TwitterDB::User.import(import_columns, users, on_duplicate_key_update: update_columns, validate: false, timestamps: false)
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
        TwitterUser.with_friends.find_in_batches(start: start, batch_size: 10) do |targets|
          uids = targets.select { |tu| processed.exclude?(tu.uid.to_i) }.map(&:uid).uniq
          twitter_users = TwitterUser.where(uid: uids).order(created_at: :asc).index_by { |tu| tu.uid.to_i }.values
          users = TwitterDB::User.where(uid: uids).index_by { |u| u.uid.to_i }

          twitter_users.each do |twitter_user|
            user = users[twitter_user.uid.to_i]

            if %i(friend_uids follower_uids).all? { |relation| twitter_user.send(relation).map(&:to_i).sort == user.send(relation).map(&:to_i).sort }
              puts "skip #{twitter_user.uid} #{twitter_user.screen_name}"
              processed << twitter_user.uid.to_i
              next
            end

            friendships = twitter_user.friends.pluck(:uid).map.with_index { |uid, i| [uid, user.uid, i] }
            followerships = twitter_user.followers.pluck(:uid).map.with_index { |uid, i| [uid, user.uid, i] }

            begin
              ActiveRecord::Base.transaction do
                if user.friends.any? || user.followers.any?
                  TwitterDB::Friendship.delete_all(user_uid: twitter_user.uid)
                  TwitterDB::Followership.delete_all(user_uid: twitter_user.uid)
                  puts "overwrite #{twitter_user.uid} #{twitter_user.screen_name}"
                end

                TwitterDB::Friendship.import(%i(friend_uid user_uid sequence), friendships, validate: false, timestamps: false)
                TwitterDB::Followership.import(%i(follower_uid user_uid sequence), followerships, validate: false, timestamps: false)
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
          break if sigint || failed

          puts "#{Time.zone.now}: targets: #{targets.size}, uids: #{uids.size}, twitter_users: #{twitter_users.size}, users: #{users.size} processed: #{processed.size}"
        end
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end
