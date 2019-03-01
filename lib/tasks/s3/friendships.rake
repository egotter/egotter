namespace :s3 do
  namespace :friendships do
    desc 'Repair'
    task repair: :environment do
      ids = ENV['IDS'].split(',')
      repaired_ids = []
      S3::Friendship.cache_enabled = false
      S3::Followership.cache_enabled = false
      S3::Profile.cache_enabled = false

      ids.each do |twitter_user_id|
        if RepairS3FriendshipsWorker.new.perform(twitter_user_id)
          puts "Repaired #{twitter_user_id}"
          repaired_ids << twitter_user_id
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
      sigint = Util::Sigint.new.trap

      start_id = ENV['START'] ? ENV['START'].to_i : 1
      start = Time.zone.now
      processed_count = 0

      TwitterUser.includes(:friendships).select(:id, :uid, :screen_name).find_in_batches(start: start_id, batch_size: 100) do |group|
        # S3::Friendship.import!(group)
        processed_count += group.size
        puts "#{now = Time.zone.now} #{group.last.id} #{(now - start) / processed_count}"

        break if sigint.trapped?
      end

      puts Time.zone.now - start
    end
  end
end
