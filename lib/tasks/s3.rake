namespace :s3 do
  desc 'Find broken data'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    start_id = ENV['START'] ? ENV['START'].to_i : 1
    start = Time.zone.now
    processed_count = 0
    found_ids = []

    (start_id..(TwitterUser.maximum(:id))).each do |twitter_user_id|
      puts "#{now = Time.zone.now} #{twitter_user_id} #{(now - start) / processed_count}" if processed_count % 1000 == 0
      processed_count += 1

      user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find_by(id: twitter_user_id)
      next unless user

      if user.s3_need_fix?
        found_ids << user.id
        puts ([user.id] + user.s3_need_fix_reasons).inspect
      end

      break if sigint.trapped?
    end

    puts found_ids.join(',') if found_ids.any?

    puts Time.zone.now - start
  end
end
