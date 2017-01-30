namespace :unfriendships do
  desc 'update unfriends and unfollowers'
  task update: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    puts "\nimport started:"

    processed = []
    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |tu_array|
        uids = tu_array.select { |tu| processed.exclude?(tu.uid.to_i) }.map(&:uid).uniq

        uids.each do |uid|
          twitter_user = TwitterUser.order(created_at: :desc).find_by(uid: uid)
          twitter_user.send(:import_unfriends)
          twitter_user.send(:import_unfollowers)

          processed << uid.to_i
          break if sigint
        end

        avg = '%3.1f' % ((Time.zone.now - process_start) / processed.size)
        puts "#{Time.zone.now} processed: #{processed.size}, avg: #{avg}, #{tu_array[0].id} - #{tu_array[-1].id}"

        break if sigint
      end
    end

    process_finish = Time.zone.now
    puts "import #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end

  desc 'verify unfriends and unfollowers'
  task verify: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    puts "\nverify started:"

    processed = []
    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |tu_array|
        uids = tu_array.select { |tu| processed.exclude?(tu.uid.to_i) }.map(&:uid).uniq

        uids.each do |uid|
          twitter_user = TwitterUser.order(created_at: :desc).find_by(uid: uid)
          unfriend_uids = twitter_user.unfriends.pluck(:uid).map(&:to_i)
          tmp_unfriend_uids = twitter_user.tmp_unfriends.map { |u| u.uid }
          unfollower_uids = twitter_user.unfollowers.pluck(:uid).map(&:to_i)
          tmp_unfollower_uids = twitter_user.tmp_unfollowers.map { |u| u.uid }

          if unfriend_uids != tmp_unfriend_uids || unfollower_uids != tmp_unfollower_uids
            puts "invalid #{twitter_user.uid} #{twitter_user.screen_name}, unfriends #{unfriend_uids == tmp_unfriend_uids} unfollowers #{unfollower_uids == tmp_unfollower_uids}"
          end

          processed << uid.to_i
          break if sigint
        end

        avg = '%3.1f' % ((Time.zone.now - process_start) / processed.size)
        puts "#{Time.zone.now} processed: #{processed.size}, avg: #{avg}, #{tu_array[0].id} - #{tu_array[-1].id}"

        break if sigint
      end
    end

    process_finish = Time.zone.now
    puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end
end