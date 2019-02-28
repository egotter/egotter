namespace :s3 do
  namespace :profiles do
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

      (start_id..(TwitterUser.maximum(:id))).each do |candidate_id|
        # next unless candidate_id % 100 == 0

        twitter_user = TwitterUser.select(:id).find_by(id: candidate_id)
        next unless twitter_user

        profile = S3::Profile.find_by(twitter_user_id: twitter_user.id)
        if profile.empty?
          puts "Invalid empty #{candidate_id} #{twitter_user.uid} #{twitter_user.screen_name}"
          found_ids << twitter_user.id
        end

        processed_count += 1
        # puts "#{now = Time.zone.now} #{candidate_id} #{(now - start) / processed_count}"

        break if sigint
      end

      puts found_ids.join(',') if found_ids.any?

      puts Time.zone.now - start
    end

    desc 'Repair'
    task repair: :environment do
      twitter_user = TwitterUser.find(ENV['ID'])

      print = -> (twitter_user) do
        profile = S3::Profile.find_by(twitter_user_id: twitter_user.id)
        puts "id:        #{twitter_user.id}"
        puts "user_info: #{twitter_user.user_info}"
        puts "profile:   #{profile[:user_info]}"
      end

      print.call(twitter_user)
      puts "Do you want to repair this record?: "

      input = STDIN.gets.chomp
      if input == 'yes' &&
          twitter_user.user_info.present? && twitter_user.user_info != '{}'
        S3::Profile.import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.user_info)
        puts 'Imported'
        print.call(twitter_user)
      end
    end

    desc 'Write profiles to S3'
    task write_to_s3: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start_id = ENV['START'] ? ENV['START'].to_i : 1
      start = Time.zone.now
      processed_count = 0

      TwitterUser.select(:id, :uid, :screen_name, :user_info).find_in_batches(start: start_id, batch_size: 100) do |group|
        S3::Profile.import!(group.select{|g| g.user_info.present? && g.user_info != '{}' })
        processed_count += group.size
        puts "#{now = Time.zone.now} #{group.last.id} #{(now - start) / processed_count}"

        break if sigint
      end

      puts Time.zone.now - start
    end
  end
end
