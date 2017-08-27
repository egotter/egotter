namespace :old_users do
  desc 'load old_users from a file'
  task load: :environment do
    old_users = []
    File.read('mongo2.json').split("\n").each do |line|
      user = JSON.parse(line)
      old_users << OldUser.new(uid: user['uid'], screen_name: '-1', secret: user['secret'], token: user['token'])
    end
    Rails.logger.silence do
      old_users.each_slice(5000).each { |users| OldUser.import(users, validate: false) }
    end
  end

  desc 'update authorized'
  task update_authorized: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    ApiClient # Avoid circular dependency

    OldUser.authorized.find_in_batches(batch_size: 100) do |users|
      Parallel.each(users, in_threads: 10) do |user|
        begin
          puts "Authorized #{user.api_client.verify_credentials[:id]}"
        rescue => e
          if e.message == 'Invalid or expired token.'
            puts "Invalid #{user.uid}"
            user.authorized = false
          else
            puts "Failed #{user.uid}"
            raise
          end
        end
      end

      changed = users.select(&:authorized_changed?)
      if changed.any?
        puts "Import #{changed.size} users"
        OldUser.import(users, on_duplicate_key_update: %i(uid authorized), validate: false)
      end

      break if sigint
    end
  end
end
