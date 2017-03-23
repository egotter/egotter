namespace :twitter_users do
  desc 'add user_info'
  task add_user_info: :environment do
    ActiveRecord::Base.connection.execute('ALTER TABLE twitter_users ADD user_info TEXT NOT NULL AFTER user_info_gzip')
  end

  desc 'copy to user_info'
  task copy_to_user_info: :environment do
    Rails.logger.silence do
      TwitterUser.find_each(batch_size: 1000) do |tu|
        tu.update!(user_info: ActiveSupport::Gzip.decompress(tu.user_info_gzip))
      end
    end
  end

  desc 'verify user_info'
  task verify_user_info: :environment do
    TwitterUser.find_each(batch_size: 1000) do |tu|
      unless tu.user_info == ActiveSupport::Gzip.decompress(tu.user_info_gzip)
        puts "id: #{tu.id} doesn't match."
      end
    end
  end

  desc 'drop user_info_gzip'
  task drop_user_info_gzip: :environment do
    ActiveRecord::Base.connection.execute("ALTER TABLE twitter_users DROP user_info_gzip")
  end

  desc 'send prompt reports'
  task send_prompt_reports: :environment do
    Rails.logger.silence { process_update_jobs(CreatePromptReportWorker) }
  end

  desc 'send update notifications'
  task send_update_notifications: :environment do
    raise NotImplementedError
    # Rails.logger.silence { process_update_jobs(UpdateTwitterUserWorker) }
  end

  def process_update_jobs(worker_klass)
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    deadline =
      case
        when ENV['DEADLINE'].nil? then nil
        when ENV['DEADLINE'].match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(ENV['DEADLINE'])
        else Time.zone.parse(ENV['DEADLINE'])
      end

    user_ids = ENV['USER_IDS']
    user_ids =
      case
        when user_ids.blank? then 1..User.maximum(:id)
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    authorized = User.where(id: user_ids, authorized: true).pluck(:id)
    active = User.active(14).where(id: authorized).pluck(:id)

    start_time = Time.zone.now
    puts "\nstarted:"
    puts %Q(  start: #{start_time}#{", deadline: #{deadline}" if deadline}, user_ids: #{user_ids.size}, authorized: #{authorized.size}, active: #{active.size}\n\n)

    processed = 0
    fatal = false
    errors = []

    active.each.with_index do |user_id, i|
      failed = false
      begin
        worker_klass.new.perform(user_id)
      rescue => e
        failed = true
        errors << {time: Time.zone.now, error: e, user_id: user_id}
        fatal = errors.size >= processed / 10
      end
      processed += 1

      if i % 100 == 0
        avg = "#{'%4.1f' % ((Time.zone.now - start_time) / (i + 1))} seconds/user"
        elapsed = "#{'%.1f' % (Time.zone.now - start_time)} seconds elapsed"
        remaining = deadline ? ", #{'%.1f' % (deadline - Time.zone.now)} seconds remaining" : ''
        puts "#{Time.zone.now}: #{user_id}, #{avg}, #{elapsed}#{remaining}"
      end

      break if (deadline && Time.zone.now > deadline) || sigint || fatal
    end

    if errors.any?
      puts "\nerrors:"
      errors.each { |error| puts "  #{error[:time]}: #{error[:user_id]}, #{error[:error].class} #{error[:error].message}" }
    end

    puts "\n#{(sigint || fatal ? 'suspended:' : 'finished:')}"
    puts "  start: #{start_time}, finish: #{Time.zone.now}, processed: #{processed}"
  end

  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    uids = ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
    failed = false
    processed = skipped = saved = 0

    uids.each do |uid|
      if TwitterUser.exists?(uid: uid)
        puts "skip because found #{uid}"
        processed += 1
        skipped += 1
        next
      end

      user = User.find_by(uid: uid, authorized: true)
      client = user ? user.api_client : Bot.api_client
      new_tu = nil

      begin
        new_tu = TwitterUser.builder(uid).client(client).login_user(user).build(validate: false)
      rescue Twitter::Error::Unauthorized => e
        if e.message == 'Not authorized.'
          puts "skip because not authorized #{uid}"
          processed += 1
          skipped += 1
          next
        elsif e.message == 'Invalid or expired token.'
          puts "\e[31mretry because invalid token #{user ? user.id : -1}\e[0m"
          user&.update(authorized: false)
          user = new_tu = nil
          client = Bot.api_client
          retry
        else
          raise
        end
      rescue Twitter::Error::NotFound => e
        if e.message == 'User not found.'
          puts "skip because not found #{uid}"
          processed += 1
          skipped += 1
          next
        else
          raise
        end
      rescue Twitter::Error::TooManyRequests => e
        puts "\e[31m#{e.message} reset in #{e.rate_limit.reset_in} #{uid}\e[0m"
        new_tu = nil
        sleep(e.rate_limit.reset_in + 1)
        puts 'Good morning! I will retry.'
        retry
      rescue Twitter::Error::Forbidden => e
        if e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
          user_id = user ? user.id : -1
          puts "\e[31mthis account is temporarily locked #{user_id}\e[0m"
          if user_id != -1
            puts "retry #{uid} with bot"
            user = new_tu = nil
            client = Bot.api_client
            retry
          else
            raise
          end
        else
          raise
        end
      end

      break if sigint || failed

      if new_tu.save
        puts "saved user_id #{new_tu.user_id}, uid #{uid}, tu_id #{new_tu.id}"
        saved += 1
        sleep 3
      else
        puts "failed #{uid} #{new_tu.errors.full_messages.join(', ')}}"
        failed = true
      end

      processed += 1

      break if sigint || failed
    end

    puts "create #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  uids: #{uids.size}, processed: #{processed}, skipped: #{skipped}, saved: #{saved}"
  end
end
