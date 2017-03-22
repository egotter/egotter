namespace :old_users do
  desc 'load old_users from a file'
  task load: :environment do
    old_users = []
    File.read('mongo2.json').split("\n").each do |line|
      user = JSON.parse(line)
      old_users << OldUser.new(uid: user['uid'], screen_name: '-1', secret: user['secret'], token: user['token'])
    end
    Rails.logger.silence do
      old_users.each_slice(5000).each { |users| OldUser.import(users, validate: false) }
    end
  end

  desc 'verify old_users'
  task verify: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    processed = 0
    authorized = 0
    process_start = Time.zone.now
    ApiClient # avoid circular dependency
    puts "\nverify started:"

    OldUser.where(authorized: false).find_in_batches(batch_size: 1000) do |users|
      Parallel.each(users, in_threads: 10) do |user|
        client = ApiClient.instance(access_token: user.token, access_token_secret: user.secret, logger: Naught.build.new)
        credential = (client.verify_credentials rescue nil)

        if credential
          user.assign_attributes(uid: credential.id, screen_name: credential.screen_name, authorized: true)
          authorized += 1
        end
        processed += 1
      end

      OldUser.import(users, on_duplicate_key_update: %i(uid screen_name authorized), validate: false)

      avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
      puts "#{Time.zone.now}: processed #{processed}, authorized #{authorized}, avg #{avg}, #{users[0].id} - #{users[-1].id}"

      break if sigint
    end

    process_finish = Time.zone.now
    elapsed = (process_finish - process_start).round(1)
    puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, processed: #{processed}, authorized: #{authorized}, elapsed: #{elapsed} seconds"
  end

  desc 'update twitter_users'
  task update: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    failed = false
    processed = 0
    created = 0
    start = ENV['START'] ? ENV['START'].to_i : 1
    process_start = Time.zone.now
    puts "\nupdate started:"

    OldUser.where(authorized: true).find_each(start: start, batch_size: 100) do |user|
      client = user.api_client

      # TODO CreateTwitterUserWorker.perform_async(...)
      begin
        twitter_user = TwitterUser.builder(user.uid).client(client).login_user(user).build

        if twitter_user&.save
          twitter_user.increment(:search_count).save
          created += 1
        end
      rescue => e
        failed = true
        puts "failed. #{e.class} #{e.message} #{user.inspect}"
      end

      processed += 1
      if processed % 10 == 0
        avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now}: processed #{processed}, created #{created}, avg #{avg}, #{user.id}"
      end

      break if sigint || failed
    end

    process_finish = Time.zone.now
    elapsed = (process_finish - process_start).round(1)
    puts "update #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, processed: #{processed}, created: #{created}, elapsed: #{elapsed} seconds"
  end
end
