namespace :close_friendships do
  desc 'update'
  task update: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    do_import = lambda do |total_uids|
      uniq_uids = total_uids.map(&:to_i).uniq
      candidate_uids = uniq_uids - TwitterDB::User.where(uid: uniq_uids).pluck(:uid)

      begin
        t_users = Bot.api_client.users(candidate_uids)
      rescue Twitter::Error::NotFound => e
        if e.message == 'No user matches for specified terms.'
          t_users = []
        else
          File.write('close_friendships_update_uids.txt', candidate_uids.join("\n"))
          raise
        end
      end

      not_found_uids = candidate_uids - t_users.map(&:id)

      if t_users.any?
        import_users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
        import_users.sort_by!(&:first)
        TwitterDB::User.import_in_batches(import_users)
      end

      puts "imported: total #{total_uids.size}, uniq #{uniq_uids.size}, candidate #{candidate_uids.size}, t_users #{t_users.size}, not found #{not_found_uids.inspect}"
    end


    processed = 0
    task_start = Time.zone.now
    start = ENV['START'] ? ENV['START'].to_i : 1
    uids = TwitterUser.where('id >= ?', start).pluck(:uid).uniq
    total_close_friend_uids = []

    uids.each do |uid|
      next if CloseFriendship.where(from_uid: uid).any?

      twitter_user = TwitterUser.latest(uid)

      close_friend_uids = twitter_user.calc_close_friend_uids
      CloseFriendship.import_from!(uid, close_friend_uids)
      total_close_friend_uids.concat close_friend_uids

      if total_close_friend_uids.size > 1000
        do_import.call(total_close_friend_uids)
        total_close_friend_uids = []
      end

      processed += 1
      avg = '%3.1f' % ((Time.zone.now - task_start) / processed)
      puts "#{Time.zone.now}: uids #{uids.size} processed #{processed}, avg #{avg}"

      break if sigint
    end

    if total_close_friend_uids.any?
      do_import.call(total_close_friend_uids)
    end

    puts "start: #{task_start}, finish: #{Time.zone.now}"
  end
end
