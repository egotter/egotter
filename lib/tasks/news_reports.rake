namespace :news_reports do
  desc 'come_back_inactive_user'
  task come_back_inactive_user: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    user_ids =
      if ENV['USER_IDS']
        ENV['USER_IDS'].remove(' ').split(',').map(&:to_i)
      else
        User.authorized.active(30).inactive(14).can_send_dm.pluck(:id)
      end

    processed = 0
    no_record = 0
    empty_count = 0
    failed = false
    dry_run = ENV['DRY_RUN'].present?
    reports_count = NewsReport.all.size

    User.where(id: user_ids).select(:id, :uid).find_each do |user|
      user_id = user.id
      twitter_user = user.twitter_user

      unless twitter_user
        puts "No record #{user_id}"
        no_record += 1
      end

      if twitter_user&.twitter_db_user&.unfollowerships&.empty?
        puts "Empty unfollowerships #{user_id}"
        empty_count += 1
      end

      begin
        NewsReport.come_back_inactive_user(user_id).deliver unless dry_run
      rescue => e
        User.find(user_id).update(authorized: false) if ex.message == 'Invalid or expired token.'
        news_reports_can_continue?(e, user_id) ? next : (failed = true)
      end

      processed += 1

      break if sigint || failed
    end

    puts "\n#{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts %Q(  user_ids: #{user_ids.size}, processed: #{processed}, no_record: #{no_record}, empty: #{empty_count}, send: #{NewsReport.all.size - reports_count}\n\n)
  end

  desc 'come_back_old_user'
  task come_back_old_user: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    user_ids =
      if ENV['USER_IDS']
        ENV['USER_IDS'].remove(' ').split(',').map(&:to_i)
      else
        OldUser.authorized.where.not(uid: User.pluck(:uid)).pluck(:id)
      end

    # Rails.logger.silence do
    #   puts "Authorized #{OldUser.authorized.size}"
    #   uids = OldUser.authorized.where.not(uid: User.pluck(:uid)).pluck(:uid)
    #   puts "Except User #{uids.size}"
    #   uids = TwitterUser.where(uid: uids).uniq.pluck(:uid).map(&:to_i)
    #   puts "With TwitterUser #{uids.size}"
    #   puts "With Unfollowership #{Unfollowership.where(from_uid: uids).count('distinct from_uid')}"
    # end

    processed = 0
    no_record = 0
    empty_count = 0
    failed = false
    dry_run = ENV['DRY_RUN'].present?
    reports_count = NewsReport.all.size

    OldUser.where(id: user_ids).select(:id, :uid).find_each do |user|
      user_id = user.id
      twitter_user = TwitterUser.latest(user.uid)

      unless twitter_user
        puts "No record #{user_id}"
        no_record += 1
      end

      if twitter_user&.twitter_db_user&.unfollowerships&.empty?
        puts "Empty unfollowerships #{user_id}"
        empty_count += 1
      end

      begin
        NewsReport.come_back_old_user(user_id).deliver unless dry_run
      rescue => e
        OldUser.find(user_id).update(authorized: false) if ex.message == 'Invalid or expired token.'
        news_reports_can_continue?(e, user_id) ? next : (failed = true)
      end

      processed += 1

      break if sigint || failed
    end

    puts "\n#{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts %Q(  user_ids: #{user_ids.size}, processed: #{processed}, no_record: #{no_record}, empty: #{empty_count}, send: #{NewsReport.all.size - reports_count}\n\n)
  end

  def news_reports_can_continue?(ex, user_id)
    if ex.message == 'Invalid or expired token.'
      puts "Invalid token #{user_id}"
      true
    elsif ex.message == 'Your account is suspended and is not permitted to access this feature.'
      puts "Suspended #{user_id}"
      true
    elsif ex.message.start_with? 'To protect our users from spam and other malicious activity,'
      puts "Temporarily locked #{user_id}"
      true
    else
      puts "#{ex.class} #{ex.message.truncate(100)} #{user_id}"
      false
    end
  end
end
