namespace :twitter2 do
  namespace :db do
    desc 'create_users2'
    task create_users2: :environment do
      ActiveRecord::Base.establish_connection(:twitter)

      ActiveRecord::Base.connection.execute <<-SQL
        CREATE TABLE `users2` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `uid` bigint(20) NOT NULL,
          `screen_name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
          `friends_size` int(11) NOT NULL DEFAULT '0',
          `followers_size` int(11) NOT NULL DEFAULT '0',
          `user_info` text COLLATE utf8mb4_unicode_ci NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `index_users_on_uid` (`uid`),
          KEY `index_users_on_screen_name` (`screen_name`),
          KEY `index_users_on_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4
      SQL

      ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    end

    desc 'copy users2'
    task copy_users2: :environment do
      klass = ENV['TABLE'].classify.constantize

      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'] : 1
      process_start = Time.zone.now
      failed = false
      import_columns = %i(uid screen_name friends_size followers_size user_info created_at updated_at)
      update_columns = %i(screen_name user_info updated_at)
      puts "\ncopy started:"

      Rails.logger.silence do
        klass.find_in_batches(start: start, batch_size: 5000) do |users_array|
          users = users_array.map do |u|
            [u.uid, u.screen_name, -1, -1, u.user_info, u.created_at, u.created_at]
          end

          begin
            TwitterDB::User2.import(import_columns, users, on_duplicate_key_update: update_columns, validate: false, timestamps: false)
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
  end
end
