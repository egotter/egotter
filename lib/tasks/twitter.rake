namespace :twitter do
  desc 'cleanup'
  task cleanup: :environment do
    Twitter::REST::Client.new.cache.cleanup
  end

  namespace :db do
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
                TwitterDB::Friendship.import_from!(twitter_user)
                TwitterDB::Followership.import_from!(twitter_user)
              end
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
