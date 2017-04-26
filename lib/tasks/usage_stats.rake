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

      twitter_user = TwitterUser.latest(uid)
      UsageStat.create_by!(uid, twitter_user.statuses)

      processed += 1
      avg = '%3.1f' % ((Time.zone.now - task_start) / processed)
      puts "#{Time.zone.now}: uids #{uids.size} processed #{processed}, avg #{avg}"

      break if sigint
    end

    puts "start: #{task_start}, finish: #{Time.zone.now}"
  end
end
