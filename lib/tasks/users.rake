namespace :users do
  desc 'update authorized'
  task update_authorized: :environment do
    sigint = Sigint.new.trap

    # Avoid circular dependency
    ApiClient
    CacheDirectory

    green = -> (str) {print "\e[32m#{str}\e[0m"}
    red = -> (str) {print "\e[31m#{str}\e[0m"}
    start = ENV['START'] ? ENV['START'].to_i : 1

    User.authorized.find_in_batches(start: start, batch_size: 200) do |users|
      Parallel.each(users, in_threads: 10) do |user|
        begin
          t_user = user.api_client.verify_credentials
          user.screen_name = t_user[:screen_name]
          green.call('.')
        rescue Twitter::Error::ServiceUnavailable => e
          puts "#{e.class} #{e.message}"
          retry
        rescue => e
          if e.message == 'Invalid or expired token.'
            user.authorized = false
            red.call('.')
          else
            puts "Failed #{user.id}"
            raise
          end
        end
      end

      puts "\n"

      authorized_changed = users.select(&:authorized_changed?)
      if authorized_changed.any?
        puts "Import authorized_changed #{authorized_changed.size}"
        Rails.logger.silence { User.import(authorized_changed, on_duplicate_key_update: %i(uid authorized), validate: false) }
      end

      screen_name_changed = users.select(&:screen_name_changed?)
      if screen_name_changed.any?
        puts "Import screen_name_changed #{screen_name_changed.size}"
        Rails.logger.silence { User.import(screen_name_changed, on_duplicate_key_update: %i(uid screen_name), validate: false) }
      end

      puts "Last id #{users[-1].id}"

      break if sigint.trapped?
    end
  end
end
