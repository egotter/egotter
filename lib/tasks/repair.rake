namespace :repair do
  desc 'check'
  task check: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    last = ENV['LAST'] ? ENV['LAST'].to_i : TwitterUser.maximum(:id)
    not_found = []
    not_consistent = []
    processed = 0
    start_time = Time.zone.now
    failed = false
    puts "\nrepair started:"

    Rails.logger.silence do
      TwitterUser.find_in_batches(start: start, batch_size: 1000) do |twitter_users|
        break if twitter_users[0].id > last

        twitter_users.each do |tu|
          break if tu.id > last

          user = TwitterDB::User.find_by(uid: tu.uid)
          unless user
            puts "TwitterDB::user is not found #{tu.id}"
            not_found << tu.id
            next
          end

          friends = [
            # tu.friends.size,
            tu.friendships.size,
            tu.friends_size,
            # tu.friends_count,
            # user.friends.size,
            # user.friendships.size,
            # user.friends_size,
            # user.friends_count
          ]

          followers = [
            # tu.followers.size,
            tu.followerships.size,
            tu.followers_size,
            # tu.followers_count,
            # user.followers.size,
            # user.followerships.size,
            # user.followers_size,
            # user.followers_count
          ]

          if friends.uniq.many? || followers.uniq.many?
            puts "fiends or followers is valid #{tu.id} #{friends.inspect} #{followers.inspect}"
            not_consistent << tu.id
          end

          break if sigint || failed
        end

        processed += twitter_users.size
        avg = '%3.1f' % ((Time.zone.now - start_time) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{twitter_users[0].id} - #{twitter_users[-1].id}"

        break if sigint || failed
      end
    end

    puts "not_found #{not_found.inspect}" if not_found.any?
    puts "not_consistent #{not_consistent.inspect}" if not_consistent.any?
    puts "repair #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, last: #{last}, processed: #{processed}, not_found: #{not_found.size}, not_consistent: #{not_consistent.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
  end

  desc 'fix'
  task fix: :environment do
    ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)
    ids.each { |id| RepairTwitterUserWorker.new.perform(id) }
  end
end