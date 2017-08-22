namespace :twitter_db do
  namespace :users do
    desc 'create TwitterDB::User'
    task create: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      uids = ENV['UIDS'].remove(' ').split(',').map(&:to_i)

      uids.each do |uid|
        TwitterUser::Batch.fetch_and_create(uid, create_twitter_user: false)
        TwitterDB::User.find_by(uid: uid).debug_print_friends
        break if sigint
      end
    end

    desc 'update TwitterDB::User'
    task update: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      failed = false
      processed = []
      skipped = 0
      skipped_reasons = []
      skip_if_with_friends = ENV['SKIP'].present?

      TwitterDB::User.select(:id, :uid, :friends_size, :followers_size).find_each.with_index do |user, i|
        if skip_if_with_friends && user.with_friends?
          skipped += 1
          skipped_reasons << "With friends #{user.uid}"
          next
        end

        twitter_user = TwitterUser::Batch.fetch_and_create(user.uid, create_twitter_user: false)
        processed << twitter_user if twitter_user

        puts("#{i + 1}") if (i % 100).zero?

        break if sigint || failed
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

      puts "\nupdate #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  uids: unknown, processed: #{processed.size}, skipped: #{skipped}"
    end
  end
end
