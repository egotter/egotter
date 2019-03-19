namespace :twitter_db do
  namespace :users do
    desc 'create TwitterDB::User'
    task create: :environment do
      uids = ENV['UIDS'].remove(' ').split(',').map(&:to_i)
      CreateTwitterDBUserWorker.perform_async(uids)
    end

    desc 'Copy from profiles'
    task copy_from_profiles: :environment do
      sigint = Util::Sigint.new.trap
      start_time = Time.zone.now
      start = ENV['START'] ? ENV['START'].to_i : 1

      update_columns = TwitterDB::User.column_names.reject {|name| %w(id created_at updated_at).include?(name)}
      processed_count = 0
      users = []

      TwitterDB::Profile.find_each(start: start, batch_size: 1000).each do |profile|
        users << TwitterDB::User.build_by_profile(profile)

        if users.size >= 1000
          TwitterDB::User.import update_columns, users.map{|u| u.slice(*update_columns).values }, on_duplicate_key_update: update_columns, validate: false
          users.clear
        end

        processed_count += 1
        puts "#{profile.id} #{processed_count} #{(Time.zone.now - start_time) / processed_count}" if processed_count % 10000 == 0

        if sigint.trapped?
          puts "Id #{profile.id}"
          break
        end
      end

      if users.any?
        TwitterDB::User.import users, validate: false
      end

      puts "Elapsed #{Time.zone.now - start_time}"
    end

    desc 'Copy from profiles by sql'
    task copy_from_profiles_by_sql: :environment do
      sigint = Util::Sigint.new.trap
      start_time = Time.zone.now
      start = ENV['START'] ? ENV['START'].to_i : 1
      processed_count = 0

      columns = %w(uid screen_name friends_count followers_count protected suspended status_created_at account_created_at statuses_count favourites_count listed_count `name` location description url geo_enabled verified lang profile_image_url_https profile_banner_url profile_link_color created_at updated_at)

      TwitterDB::Profile.select(:id).find_in_batches(start: start, batch_size: 100_000).each do |profiles|

        sql = <<~SQL
          INSERT INTO twitter_db_users (#{columns.join(', ')})
          SELECT #{columns.join(', ')}
          FROM twitter_db_profiles p
          WHERE id in (#{profiles.map(&:id).join(', ')})
          ON DUPLICATE KEY UPDATE
          #{columns.map{|c| "#{c} = p.#{c}"}.join(', ')}
        SQL

        ActiveRecord::Base.connection.execute(sql)

        processed_count += profiles.size
        puts "#{profiles.last.id} #{processed_count} #{sprintf('%.5f', (Time.zone.now - start_time) / processed_count)}"

        if sigint.trapped?
          puts "Id #{profiles.last.id}"
          break
        end
      end
    end
  end
end
