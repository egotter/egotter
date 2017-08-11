namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    persisted_uids = TwitterUser.uniq.pluck(:uid).map(&:to_i)

    specified_uids =
      if ENV['UIDS']
        ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
      else
        User.authorized.pluck(:uid).map(&:to_i).reject { |uid| persisted_uids.include? uid }.take(500)
     end

    failed = false
    processed = []
    skipped = 0
    skipped_reasons = []

    specified_uids.each do |uid|
      if persisted_uids.include? uid
        skipped += 1
        skipped_reasons << "Persisted #{uid}"
        next
      end

      twitter_user = TwitterUsers.fetch_and_create(uid)
      processed << twitter_user if twitter_user

      break if sigint || failed
    end

    if processed.any?
      users = TwitterDB::User.where(uid: processed.take(500).map(&:uid)).index_by(&:uid)
      puts "\nprocessed:"
      puts processed.take(500).map { |tu|
        u = users[tu.uid.to_i]
        "  #{tu.uid} [#{tu.friends_size}, #{tu.friends_count}, #{u&.friends_size}, #{u&.friends_count}] [#{tu.followers_size}, #{tu.followers_count}, #{u&.followers_size}, #{u&.followers_count}]"
      }.join("\n")
    end

    if skipped_reasons.any?
      puts "\nskipped reasons:"
      puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
    end

    puts "\ncreate #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  uids: #{specified_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
  end
end
