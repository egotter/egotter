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
    process_update_jobs(CreatePromptReportWorker)
  end

  desc 'send update notifications'
  task send_update_notifications: :environment do
    process_update_jobs(UpdateTwitterUserWorker)
  end

  def process_update_jobs(worker_klass)
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

    authorized = User.where(id: user_ids, authorized: true).to_a
    active = User.active(14).where(id: authorized.map(&:id)).to_a

    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start_time = Time.zone.now
    puts "\nstarted:"
    puts "  start: #{start_time}, user_ids: #{user_ids.size}, authorized: #{authorized.size}, active: #{active.size}, deadline: #{deadline}\n\n"

    processed = 0
    fatal = false
    errors = []

    active.map(&:id).each.with_index do |user_id, i|
      start = Time.zone.now
      failed = false
      begin
        worker_klass.new.perform(user_id)
      rescue => e
        failed = true
        errors << {time: Time.zone.now, error: e, user_id: user_id}
        fatal = errors.select { |error| error[:time] > 60.seconds.ago }.size >= 10
      end
      processed += 1

      if i % 10 == 0
        avg = ", #{'%4.1f' % ((Time.zone.now - start_time) / (i + 1))} seconds/user"
        elapsed = ", #{'%.1f' % (Time.zone.now - start_time)} seconds elapsed"
        remaining = deadline ? ", #{'%.1f' % (deadline - Time.zone.now)} seconds remaining" : ''
      else
        avg = elapsed = remaining = ''
      end
      status = failed ? ', failed' : ''
      puts "#{Time.zone.now}: #{user_id}, #{'%4.1f' % (Time.zone.now - start)} seconds#{avg}#{elapsed}#{remaining}#{status}"

      break if (deadline && Time.zone.now > deadline) || sigint || fatal
    end

    if errors.any?
      puts "\nerrors:"
      errors.each { |error| puts "  #{error[:time]}: #{error[:user_id]}, #{error[:error].class} #{error[:error].message}" }
    end

    puts "\n#{(sigint || fatal ? 'suspended:' : 'finished:')}"
    puts "  start: #{start_time}, finish: #{Time.zone.now}, processed: #{processed}"
  end

  desc 'import unfriends and unfollowers'
  task import_unfriends_and_unfollowers: :environment do
    start_day = (ENV['START'] ? Time.zone.parse(ENV['START']) : 7.days.ago).beginning_of_day
    end_day = (ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now).end_of_day
    interval = ENV['INTERVAL'] ? ENV['INTERVAL'].to_f : nil
    task_start = Time.zone.now

    puts "\nstarted:"
    puts "  start: #{task_start}\n\n"

    Rails.logger.silence do
      uids = TwitterUser.where(created_at: start_day..end_day).uniq.pluck(:uid)
      total = uids.size

      uids.each.with_index do |uid, i|
        tu = TwitterUser.order(created_at: :desc).find_by(uid: uid)
        tu.send(:import_unfriends) if tu.unfriends.empty?
        tu.send(:import_unfollowers) if tu.unfollowers.empty?
        sleep interval

        if i % 10 == 0
          avg = '%4.1f' % ((Time.zone.now - task_start) / (i + 1))
          sleeping = interval ? ", interval: #{interval}" : ''
          puts "#{Time.zone.now}: total: #{total}, processed: #{i + 1}, avg: #{avg}#{sleeping}"
        end
      end
    end

    puts "\nfinished:"
    puts "  start: #{task_start}, finish: #{Time.zone.now}"
  end

  desc 'fix counts'
  task fix_counts: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    start_time = Time.zone.now
    failed = false
    puts "\nfix counts started:"

    Rails.logger.silence do
      TwitterUser.find_in_batches(start: start, batch_size: 5000) do |array|
        twitter_users = array.map do |tu|
          [tu.id, 0, '', '', tu.friends.size, tu.followers.size, 0, start_time, start_time]
        end

        begin
          TwitterUser.import(%i(id uid screen_name user_info friends_size followers_size user_id created_at updated_at), twitter_users,
                       validate: false, timestamps: false, on_duplicate_key_update: %i(friends_size followers_size))
          puts "#{Time.zone.now}: #{twitter_users.first[0]} - #{twitter_users.last[0]}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end

        break if sigint || failed
      end
    end

    puts "fix counts #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, total: #{(Time.zone.now - start_time).round(1)} seconds"
  end

  desc 'copy_relations'
  task copy_relations: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
    process_start = Time.zone.now
    failed = false
    puts "\ncopy started:"

    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |twitter_users|
        twitter_users.each do |twitter_user|
          begin
            ActiveRecord::Base.transaction do
              Friendship.import_from!(twitter_user)
              Followership.import_from!(twitter_user)
            end
          rescue => e
            failed = true
            puts "#{twitter_user.uid} #{twitter_user.screen_name} #{e.class} #{e.message}"
          end
          break if sigint || failed
        end
        break if sigint || failed

        puts "#{Time.zone.now}: twitter_users: #{twitter_users.size}, #{twitter_users[0].id} - #{twitter_users[-1].id}"
      end
    end

    process_finish = Time.zone.now
    puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end

  desc 'verify_relations'
  task verify_relations: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 100
    process_start = Time.zone.now
    puts "\nverify started:"

    processed = 0
    invalid = []
    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |twitter_users_array|
        TwitterUser.where(id: twitter_users_array.map(&:id)).each do |twitter_user|
          friends_size = [
              twitter_user.friends.size,
              twitter_user.friends_size,
              twitter_user.friendships.size,
              Friendship.where(from_id: twitter_user.id).size,
          ]

          followers_size = [
              twitter_user.followers.size,
              twitter_user.followers_size,
              twitter_user.followerships.size,
              Followership.where(from_id: twitter_user.id).size,
          ]

          if [friends_size, followers_size].any? { |array| !array.combination(2).all? { |a, b| a == b } }
            invalid << twitter_user.id
            puts "invalid id: #{user.id}, uid: #{user.uid}, screen_name: #{user.screen_name}, friends: #{friends_size.inspect}, followers: #{followers_size.inspect}"
          end

          break if sigint
        end
        processed += twitter_users_array.size

        avg = '%4.1f' % (1000 * (Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now} processed: #{processed}, avg(1000): #{avg}, #{twitter_users_array[0].id} - #{twitter_users_array[-1].id}"

        break if sigint
      end
    end

    process_finish = Time.zone.now
    puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    puts "invalid #{invalid.inspect}" if invalid.any?
  end
end
