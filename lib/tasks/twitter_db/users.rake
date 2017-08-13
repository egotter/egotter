namespace :twitter_db do
  namespace :users do
    desc 'update TwitterDB::User'
    task update: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      friendless_uids = []
      TwitterDB::User.friendless.select(:id, :uid).find_in_batches(batch_size: 100) do |users|
        friendless_uids += users.map(&:uid)
        break if friendless_uids.size >= 500
      end

      failed = false
      processed = []
      skipped = 0
      skipped_reasons = []

      friendless_uids.each do |uid|
        twitter_user = TwitterUser.fetch_and_create(uid)
        processed << twitter_user if twitter_user

        break if sigint || failed
      end

      if processed.any?
        puts "\ncreated:"
        processed.take(500).each do |twitter_user|
          print "  #{twitter_user.uid}"
          twitter_user.debug_print_friends
        end
      end

      if skipped_reasons.any?
        puts "\nskipped reasons:"
        puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
      end

      puts "\nupdate #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  uids: #{friendless_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
    end
  end
end
