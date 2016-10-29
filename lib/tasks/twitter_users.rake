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
      case
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    user_ids.each do |user_id|
      start = Time.zone.now
      UpdateTwitterUserWorker.new.perform(user_id)
      puts "#{Time.zone.now}: #{user_id}, #{(Time.zone.now - start).round(1)} seconds"
    end
  end

  namespace :benchmark do
    desc 'removing'
    task removing: :environment do
      uid = ENV['ID'].to_i
      count = ENV['COUNT'] ? ENV['COUNT'].to_i : 3

      count.times do
        ActiveRecord::Base.connection.query_cache.clear

        ActiveRecord::Base.benchmark('friends.to_a.empty? && followers.to_a.empty? -> SELECT *') do
          TwitterUser.where(uid: uid).order(created_at: :asc).reject{|tu| tu.friends.to_a.empty? && tu.followers.to_a.empty? }.each_cons(2).map do |older, newer|
            unless newer.nil? || older.nil? || newer.friends.empty?
              older.friends - newer.friends
            end
          end.compact.flatten.reverse
        end
      end

      count.times do
        ActiveRecord::Base.connection.query_cache.clear

        ActiveRecord::Base.benchmark('friends.size == 0 && followers.size == 0 -> SELECT count(*)') do
          TwitterUser.where(uid: uid).order(created_at: :asc).reject{|tu| tu.friends.size == 0 && tu.followers.size == 0 }.each_cons(2).map do |older, newer|
            unless newer.nil? || older.nil? || newer.friends.empty?
              older.friends - newer.friends
            end
          end.compact.flatten.reverse
        end
      end

      count.times do
        ActiveRecord::Base.connection.query_cache.clear

        ActiveRecord::Base.benchmark('friends.empty? && followers.empty? -> SELECT 1') do
          TwitterUser.where(uid: uid).order(created_at: :asc).reject{|tu| tu.friends.empty? && tu.followers.empty? }.each_cons(2).map do |older, newer|
            unless newer.nil? || older.nil? || newer.friends.empty?
              older.friends - newer.friends
            end
          end.compact.flatten.reverse
        end
      end

      count.times do
        ActiveRecord::Base.connection.query_cache.clear

        ActiveRecord::Base.benchmark('includes(:friends, :followers) before friends.empty? && followers.empty?') do
          TwitterUser.includes(:friends, :followers).where(uid: uid).order(created_at: :asc).reject{|tu| tu.friends.empty? && tu.followers.empty? }.each_cons(2).map do |older, newer|
            unless newer.nil? || older.nil? || newer.friends.empty?
              older.friends - newer.friends
            end
          end.compact.flatten.reverse
        end
      end
    end
  end
end
