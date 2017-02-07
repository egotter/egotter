namespace :page_caches do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    process_start = Time.zone.now
    failed = false
    processed = 0
    puts "\ncreate started:"

    TwitterUser.pluck(:uid).uniq.each do |uid|
      begin
        CreatePageCacheWorker.new.perform(uid)
      rescue => e
        puts "#{e.class} #{e.message} #{uid}"
        failed = true
      end

      processed += 1
      if processed % 10 == 0
        avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}"
      end

      break if sigint || failed
    end

    process_finish = Time.zone.now
    puts "create #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end
end
