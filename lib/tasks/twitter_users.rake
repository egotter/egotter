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
    Rails.logger.silence { process_update_jobs(UpdateTwitterUserWorker) }
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

    authorized = User.where(id: user_ids, authorized: true).pluck(:id)
    active = User.active(14).where(id: authorized).pluck(:id)

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

    active.each.with_index do |user_id, i|
      failed = false
      begin
        worker_klass.new.perform(user_id)
      rescue => e
        failed = true
        errors << {time: Time.zone.now, error: e, user_id: user_id}
        fatal = errors.select { |error| error[:time] > 60.seconds.ago }.size >= 10
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
      found = []
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
              found << tu.id
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
              found << tu.id
            end

            break if sigint || failed
          end

          processed += twitter_users.size
          avg = '%3.1f' % ((Time.zone.now - start_time) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{twitter_users[0].id} - #{twitter_users[-1].id}"

          break if sigint || failed
        end
      end

      puts "found #{found.inspect}" if found.any?
      puts "repair #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{start}, last: #{last}, processed: #{processed}, found #{found.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
    end

    desc 'fix'
    task fix: :environment do
      ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)
      ids.each { |id| RepairTwitterUserWorker.new.perform(id) }
    end
  end
end
