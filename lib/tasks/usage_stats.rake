namespace :usage_stats do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    processed = 0
    task_start = Time.zone.now
    start = ENV['START'] ? ENV['START'].to_i : 1
    uids = TwitterUser.where('id >= ?', start).pluck(:uid).uniq

    uids.each do |uid|
      next if UsageStat.exists?(uid: uid)

      statuses = TwitterUser.latest(uid).statuses
      UsageStat.update_with_statuses!(uid, statuses)

      processed += 1
      if processed % 100 == 0
        avg = '%3.1f' % ((Time.zone.now - task_start) / processed)
        puts "#{Time.zone.now}: uids #{uids.size} processed #{processed}, avg #{avg}"
      end
      break if sigint
    end

    puts "start: #{task_start}, finish: #{Time.zone.now}"
  end

  namespace :update do
    desc 'tweet_clusters'
    task tweet_clusters: :environment do
      UsageStat.find_each do |stat|
        statuses = TwitterUser.latest(stat.uid).statuses
        stat.update!(tweet_clusters_json: ApiClient.dummy_instance.tweet_clusters(statuses, limit: 100).to_json)
      end
    end
  end
end
