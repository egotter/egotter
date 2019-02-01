namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = Util::Sigint.new.trap

    persisted_uids = nil

    specified_uids =
      if ENV['UIDS']
        ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
      else
        User.authorized.pluck(:uid).map(&:to_i).take(500)
     end

    failed = false
    processed = []
    skipped = 0
    skipped_reasons = []
    skip_if_persisted = ENV['SKIP'].present?

    specified_uids.each.with_index do |uid, i|
      next if uid == User::EGOTTER_UID
      if skip_if_persisted
        persisted_uids ||= TwitterUser.uniq.pluck(:uid).map(&:to_i)
        if persisted_uids.include?(uid)
          skipped += 1
          skipped_reasons << "Persisted #{uid}"
          next
        end
      end

      twitter_user = TwitterUser::Batch.fetch_and_create(uid)
      processed << twitter_user if twitter_user

      puts("#{i + 1}/#{specified_uids.size}") if (i % 100).zero?

      break if sigint.trapped? || failed
    end

    if processed.any?
      puts "\ncreated:"
      processed.take(500).each do |twitter_user|
        print "  #{twitter_user.uid} "
        twitter_user.debug_print_friends
      end
    end

    if skipped_reasons.any?
      puts "\nskipped reasons:"
      puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
    end

    puts "\ncreate #{(sigint.trapped? || failed ? 'suspended:' : 'finished:')}"
    puts "  uids: #{specified_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
  end

  desc 'check'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    STDOUT.sync = true
    Rails.logger.level = Logger::WARN

    start = ENV['START'] ? ENV['START'].to_i : 1
    columns = %i(id uid friends_size followers_size)

    TwitterUser.select(*columns).find_each(start: start, batch_size: 1000) do |twitter_user|
      if twitter_user.inconsistent_because_import_didnt_run?
        puts "#{twitter_user.inspect} friendships: #{twitter_user.friendships.size} followerships: #{twitter_user.followerships.size} latest: #{twitter_user.latest?} one: #{twitter_user.one?}"
      end

      break if sigint.trapped?
    end
  end
end
