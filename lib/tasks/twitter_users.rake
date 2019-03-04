namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = Util::Sigint.new.trap

    specified_uids = ENV['UIDS'].split(',').map(&:to_i)
    created_ids = []

    specified_uids.each do |uid|
      if TwitterUser.exists?(uid: uid)
        puts "Already persisted. #{uid}"
        next
      end

      user = User.authorized.find_by(uid: uid)
      client = user ? user.api_client : Bot.api_client
      builder = TwitterUser.builder(uid).client(client).login_user(user)

      begin
        twitter_user = builder.build
      rescue Twitter::Error::Unauthorized, Twitter::Error::NotFound => e
        puts "Error: #{uid} #{e.class} #{e.message}"

        if e.message == 'Not authorized.' || e.message == 'User not found.'
          next
        else
          raise
        end
      end

      if twitter_user.errors.any?
        puts "Validation error: #{uid} #{twitter_user.errors.full_messages.join(', ')}"
        next
      end

      TwitterDB::User.import_by(twitter_user: twitter_user)

      if twitter_user.save
        created_ids << twitter_user.id
        next
      end

      if TwitterUser.exists?(uid: twitter_user.uid)
        puts "Validation error: #{uid} Not changed"
      else
        puts "Validation error: #{uid} #{twitter_user.errors.full_messages.join(', ')}"
      end

      break if sigint.trapped?
    end

    puts created_ids.join(',') if created_ids.any?
  end

  desc 'check'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    STDOUT.sync = true
    Rails.logger.level = Logger::WARN
    green = -> (str) {print "\e[32m#{str}\e[0m"}
    last_id = -1
    found_ids = []

    start = ENV['START'] ? ENV['START'].to_i : 1
    columns = %i(id uid friends_size followers_size)

    TwitterUser.select(*columns).find_each(start: start, batch_size: 1000) do |twitter_user|
      if twitter_user.import_batch_failed?
        puts "#{twitter_user.inspect} friendships: #{twitter_user.friendships.size} followerships: #{twitter_user.followerships.size} latest: #{twitter_user.latest?} one: #{twitter_user.one?}"
        found_ids << twitter_user.id
      else
        green.call('.')
      end

      last_id = twitter_user.id

      break if sigint.trapped?
    end

    puts "\n"
    puts "Found ids #{found_ids.join(',')}"
    puts "last id #{last_id}"
  end
end
