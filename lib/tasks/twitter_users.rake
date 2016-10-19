namespace :twitter_users do
  desc 'add user_info'
  task add_user_info: :environment do
    ActiveRecord::Base.connection.execute('ALTER TABLE twitter_users ADD user_info TEXT NOT NULL AFTER user_info_gzip')
  end

  desc 'copy to user_info'
  task copy_to_user_info: :environment do
    TwitterUser.find_each(batch_size: 1000) do |tu|
      tu.update!(user_info: ActiveSupport::Gzip.decompress(tu.user_info_gzip))
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

  desc 'add an update job'
  task add_update_job: :environment do
    UpdateTwitterUserWorker.perform_async(ENV['USER_ID'].to_i)
  end

  desc 'add update jobs'
  task add_update_jobs: :environment do
    user_ids = ENV['USER_IDS']
    next if user_ids.blank?

    user_ids =
      if user_ids.include?('..')
        Range.new(*user_ids.split('..').map(&:to_i))
      else
        user_ids.split(',').map(&:to_i)
      end

    user_ids.each do |user_id|
      start = Time.zone.now
      UpdateTwitterUserWorker.new.perform(user_id)
      puts "#{Time.zone.now}: #{user_id}, #{(Time.zone.now - start).round(1)} seconds"
    end
  end
end