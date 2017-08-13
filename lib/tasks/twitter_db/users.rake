namespace :twitter_db do
  namespace :users do
    desc 'update TwitterDB::User'
    task update: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      with_friends_uids = TwitterDB::User.with_friends.pluck(:uid)

      specified_uids =
        if ENV['UIDS']
          ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
        else
          User.authorized.pluck(:uid).map(&:to_i).reject { |user| with_friends_uids.include? user.uid }.take(500)
        end

      failed = false
      processed = []
      skipped = 0
      skipped_reasons = []

      specified_uids.each do |uid|
        if with_friends_uids.include? uid
          skipped += 1
          skipped_reasons << "With friends #{uid}"
          next
        end

        raise 'WIP'

        twitter_user = TwitterUser.fetch_and_create(uid)
        processed << twitter_user.uid.to_i if twitter_user

        break if sigint || failed
      end

      if processed.any?
        users = TwitterDB::User.where(uid: processed.take(500)).index_by(&:uid)
        puts "\nprocessed:"
        puts processed.take(500).map { |uid|
          u = users[uid.to_i]
          "  #{uid} [#{u&.friends_size}, #{u&.friends_count}] [#{u&.followers_size}, #{u&.followers_count}]"
        }.join("\n")
      end

      if skipped_reasons.any?
        puts "\nskipped reasons:"
        puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
      end

      puts "\nupdate #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  uids: #{specified_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
    end
  end
end
