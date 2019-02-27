namespace :s3 do
  namespace :followerships do
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

      (start_id..(TwitterUser.maximum(:id))).each do |candidate_id|
        # next unless candidate_id % 100 == 0

        twitter_user = TwitterUser.find_by(id: candidate_id)
        next unless twitter_user

        followership = S3::Followership.find_by(twitter_user_id: twitter_user.id)
        if followership.empty?
          puts "Invalid empty #{candidate_id} #{twitter_user.uid} #{twitter_user.screen_name}"
        end

        if twitter_user.id != followership[:twitter_user_id] ||
            twitter_user.uid != followership[:uid] ||
            twitter_user.screen_name != followership[:screen_name] ||
            twitter_user.follower_uids.size != followership[:follower_uids].size
          puts "Invalid keys #{candidate_id} #{twitter_user.uid} #{twitter_user.screen_name}"
        end

        follower_uids = followership[:follower_uids]

        twitter_user.follower_uids.each.with_index do |follower_uid, i|
          unless follower_uid == follower_uids[i]
            puts "Invalid ids #{candidate_id} #{twitter_user.uid} #{twitter_user.screen_name}"
            break
          end
        end

        processed_count += 1
        # puts "#{now = Time.zone.now} #{candidate_id} #{(now - start) / processed_count}"

        break if sigint
      end

      puts Time.zone.now - start
    end

    desc 'Write followerships to S3'
    task write_to_s3: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start_id = ENV['START'] ? ENV['START'].to_i : 1
      start = Time.zone.now
      processed_count = 0

      TwitterUser.includes(:followerships).select(:id, :uid, :screen_name).find_in_batches(start: start_id, batch_size: 100) do |group|
        S3::Followership.import!(group)
        processed_count += group.size
        puts "#{now = Time.zone.now} #{group.last.id} #{(now - start) / processed_count}"

        break if sigint
      end

      puts Time.zone.now - start
    end
  end
end
