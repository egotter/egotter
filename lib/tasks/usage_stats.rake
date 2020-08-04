namespace :usage_stats do
  desc 'create'
  task create: :environment do
    sigint = Sigint.new.trap

    processed = 0
    skipped = 0
    task_start = Time.zone.now
    start = ENV['START'] ? ENV['START'].to_i : 1
    force_update = !!ENV['UPDATE']
    uids = TwitterUser.where('id >= ?', start).pluck(:uid).uniq

    Rails.logger.silence do
      uids.each do |uid|
        if !force_update && UsageStat.exists?(uid: uid)
          skipped += 1
          next
        end

        statuses = TwitterUser.latest_by(uid: uid).status_tweets
        next if statuses.empty?
        stat = UsageStat.builder(uid).statuses(statuses).build
        unless stat.save
          puts "Failed #{stat.errors.full_messages}"
          break
        end

        processed += 1
        if processed % 100 == 0
          avg = '%3.1f' % ((Time.zone.now - task_start) / processed)
          puts "#{Time.zone.now}: uids #{uids.size} processed #{processed} skipped #{skipped}, avg #{avg}"
        end
        break if sigint.trapped?
      end
    end

    puts "start: #{task_start}, finish: #{Time.zone.now}"
  end

  desc 'update'
  task update: :environment do
    sigint = Sigint.new.trap
    processed = 0
    start = Time.zone.now

    logger = lambda do
      time = Time.zone.now
      puts "#{time.to_s} processed #{processed} elapsed #{sprintf("%.3f sec", time - start)}"
    end

    UsageStat.where(tweet_times: nil).find_each do |usage_stat|
      stat = UsageStat.builder(usage_stat.uid).build
      stat.save! if stat

      logger.call if (processed += 1) % 1000 == 0

      break if sigint.trapped?
    end
  end
end
