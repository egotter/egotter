namespace :one_sided_friendships do
  desc 'refresh one_sided_friendships, one_sided_followerships and mutual_friendships'
  task refresh: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    failed = false
    processed = 0
    puts "\nrefresh started:"

    Rails.logger.silence do
      TwitterUser.pluck(:uid).uniq.each_slice(batch_size) do |uids|
        uids.each do |uid|
          begin
            twitter_user = TwitterUser.latest(uid)
            OneSidedFriendship.import_from!(twitter_user.uid, twitter_user.calc_one_sided_friend_uids)
            OneSidedFollowership.import_from!(twitter_user.uid, twitter_user.calc_one_sided_follower_uids)
            MutualFriendship.import_from!(twitter_user.uid, twitter_user.calc_mutual_friend_uids)
          rescue => e
            failed = true
            puts "#{twitter_user.id} #{twitter_user.uid} #{twitter_user.screen_name} #{e.class} #{e.message}"
          end

          break if sigint || failed
        end

        processed += uids.size
        avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}"

        break if sigint || failed
      end
    end

    process_finish = Time.zone.now
    puts "refresh #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end
end