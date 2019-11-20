namespace :notification_settings do
  desc 'update permission_level'
  task update_permission_level: :environment do
    sigint = Util::Sigint.new.trap

    # Avoid circular dependency
    ApiClient
    PermissionLevelClient
    CacheDirectory

    green = -> (str) {print "\e[32m#{str}\e[0m"}
    red = -> (str) {print "\e[31m#{str}\e[0m"}
    start = ENV['START'] ? ENV['START'].to_i : 1

    User.includes(:notification_setting).authorized.find_in_batches(start: start, batch_size: 1000) do |users|
      Parallel.each(users, in_threads: 10) do |user|
        begin
          level = PermissionLevelClient.new(user.api_client.twitter).permission_level
          user.notification_setting.permission_level = level
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
        Rails.logger.silence { User.import(authorized_changed, on_duplicate_key_update: %i(authorized), validate: false, timestamps: false) }
      end

      level_changed = users.select { |user| user.notification_setting.permission_level_changed? }.map(&:notification_setting)
      if level_changed.any?
        puts "Import level_changed #{level_changed.size}"
        Rails.logger.silence { NotificationSetting.import(level_changed, on_duplicate_key_update: %i(permission_level), validate: false, timestamps: false) }
      end

      puts "Last id #{users[-1].id}"

      break if sigint.trapped?
    end
  end
end
