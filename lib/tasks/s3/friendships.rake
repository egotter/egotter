namespace :s3 do
  namespace :friendships do
    desc 'Check'
    task check: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start_id = ENV['START'] ? ENV['START'].to_i : 1
      start = Time.zone.now
      processed_count = 0
      found_ids = []

      print = -> (reason, user) do
        puts "#{reason}\t#{user.id}\t#{user.uid}\t#{user.screen_name}\t#{user.friends_size}\t#{user.followers_size}"
      end

      (start_id..(TwitterUser.maximum(:id))).each do |candidate_id|
        # next unless candidate_id % 100 == 0
        puts "#{now = Time.zone.now} #{candidate_id} #{(now - start) / processed_count}" if processed_count % 1000 == 0
        processed_count += 1

        twitter_user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size).find_by(id: candidate_id)
        next unless twitter_user

        unless S3::Friendship.exists?(twitter_user_id: twitter_user.id)
          puts "Not found #{candidate_id}"
          found_ids << twitter_user.id
          next
        end

        friendship = S3::Friendship.find_by(twitter_user_id: twitter_user.id)
        if friendship.empty?
          print.call('Empty', twitter_user)
          found_ids << twitter_user.id
          next
        end

        if twitter_user.id != friendship[:twitter_user_id] ||
            twitter_user.uid != friendship[:uid] ||
            twitter_user.screen_name != friendship[:screen_name]

          print.call('Keys', twitter_user)
          found_ids << twitter_user.id
          next
        end

        if twitter_user.friends_size != friendship[:friend_uids].size
          print.call('friends_size', twitter_user)
          found_ids << twitter_user.id
        end

        break if sigint
      end

      puts found_ids.join(',') if found_ids.any?

      puts Time.zone.now - start
    end

    desc 'Repair'
    task repair: :environment do
      ids = ENV['IDS'].split(',')
      repaired_ids = []

      TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size).where(id: ids).find_each do |user|
        if twitter_user.friends_size == 0 &&
            twitter_user.followers_size == 0 &&
            !S3::Friendship.exists?(twitter_user_id: user.id)

          S3::Friendship.import_from!(user.id, user.uid, user.screen_name, [])

          unless S3::Followership.exists?(twitter_user_id: user.id)
            S3::Followership.import_from!(user.id, user.uid, user.screen_name, [])
          end

          puts "Repaired #{user.id}"
          repaired_ids << user.id
          next
        end

      end

      print = -> (twitter_user) do
        friendship = S3::Friendship.find_by(twitter_user_id: twitter_user.id)
        followership = S3::Followership.find_by(twitter_user_id: twitter_user.id)
        puts "id:    #{twitter_user.id}"
        puts "count: #{twitter_user.friends_count}, #{twitter_user.followers_count}"
        puts "size:  #{twitter_user.friends_size}, #{twitter_user.followers_size}"
        puts "uids:  #{twitter_user.friend_uids.size}, #{twitter_user.follower_uids.size}"
        puts "s3:    #{friendship[:friend_uids]&.size}, #{followership[:follower_uids]&.size}"
      end

      puts "ids #{ids.size}, repair #{repaired_ids.size}"

      # print.call(twitter_user)
      # puts "Do you want to repair this record?: "
      #
      # input = STDIN.gets.chomp
      # if input == 'yes'
      #   # S3::Friendship.import_by!(twitter_user: twitter_user)
      #   puts 'Imported'
      #   print.call(twitter_user)
      # end
    end

    desc 'Write friendships to S3'
    task write_to_s3: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start_id = ENV['START'] ? ENV['START'].to_i : 1
      start = Time.zone.now
      processed_count = 0

      TwitterUser.includes(:friendships).select(:id, :uid, :screen_name).find_in_batches(start: start_id, batch_size: 100) do |group|
        # S3::Friendship.import!(group)
        processed_count += group.size
        puts "#{now = Time.zone.now} #{group.last.id} #{(now - start) / processed_count}"

        break if sigint
      end

      puts Time.zone.now - start
    end
  end
end
