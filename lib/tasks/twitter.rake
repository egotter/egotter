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
          uids = users_array.map(&:uid).uniq.map(&:to_i)
          users = twitter_db_users_find_or_initialize_by(uids).index_by(&:uid)

          users_array.each do |u|
            user = users[u.uid.to_i]
            if user.new_record?
              user.assign_attributes(screen_name: u.screen_name, friends_size: -1, followers_size: -1, user_info: u.user_info, created_at: u.created_at, updated_at: u.created_at)
            else
              if user.updated_at < u.created_at
                user.assign_attributes(screen_name: u.screen_name, user_info: u.user_info, updated_at: u.created_at)
              end
            end
          end

          changed, not_changed = users.values.partition { |u| u.changed? }
          new_record, persisted = changed.partition { |u| u.new_record? }
          begin
            if new_record.any?
              TwitterDB::User.import(changed.select(&:new_record?), validate: false, timestamps: false)
            end
            if persisted.any?
              TwitterDB::User.import(changed.select(&:persisted?), on_duplicate_key_update: %i(screen_name user_info updated_at), validate: false, timestamps: false)
            end
            puts "#{Time.zone.now} users: #{users.size}, changed: #{changed.size}(#{new_record.size}, #{persisted.size}), not_changed: #{not_changed.size}, #{users_array[0].id} - #{users_array[-1].id}"
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

    def twitter_db_users_find_or_initialize_by(uids)
      users = TwitterDB::User.where(uid: uids)
      users + (uids - users.map(&:uid)).map { |uid| TwitterDB::User.new(uid: uid) }
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
