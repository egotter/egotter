namespace :followers do
  desc 'reset'
  task reset: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table}")
    ActiveRecord::Base.connection.execute("CREATE TABLE #{table} like followers")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP updated_at")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} ROW_FORMAT = COMPRESSED")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} KEY_BLOCK_SIZE = 4")
  end

  desc 'drop_index'
  task drop_index: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_followers_on_uid")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_followers_on_from_id")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_followers_on_screen_name")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_followers_on_created_at")
  end

  desc 'add_index'
  task add_index: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    ActiveRecord::Base.connection.execute("CREATE INDEX index_followers_on_from_id ON #{table} (from_id)")
  end

  desc 'rename'
  task rename: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    ActiveRecord::Base.connection.execute('ALTER TABLE followers RENAME old_followers')
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} RENAME followers")
  end

  desc 'copy'
  task copy: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    eval("class #{table.classify} < ActiveRecord::Base; end")
    klass = table.classify.constantize

    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'].present? ? ENV['START'] : 1
    start_time = Time.zone.now
    failed = false
    puts "\ncopy started:"

    Rails.logger.silence do
      Follower.find_in_batches(start: start, batch_size: 5000) do |followers_array|
        followers = followers_array.map do |f|
          [f.id, f.uid, f.screen_name, f.user_info, f.from_id, f.created_at]
        end

        begin
          klass.import(%i(id uid screen_name user_info from_id created_at), followers, validate: false)
          puts "#{Time.zone.now}: #{followers.first[0]} - #{followers.last[0]}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end

        break if sigint || failed
      end
    end

    puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, total: #{(Time.zone.now - start_time).round(1)} seconds"
  end

  desc 'verify'
  task verify: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    eval("class #{table.classify} < ActiveRecord::Base; end")
    klass = table.classify.constantize

    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'].present? ? ENV['START'] : 1
    start_time = Time.zone.now
    failed = false
    attrs = %i(id uid screen_name user_info from_id created_at)
    puts "\nverify started:"

    Rails.logger.silence do
      sql = <<-"SQL".strip_heredoc
        SELECT auto_increment at
        FROM information_schema.tables
        WHERE table_schema = "egotter_#{Rails.env}" AND table_name = :table
      SQL

      if Follower.find_by_sql([sql, table: :followers]).first.at != klass.find_by_sql([sql, table: table]).first.at
        puts "#{Time.zone.now}: auto_increment id is invalid."
      end

      Follower.find_in_batches(start: start, batch_size: 5000) do |followers_array|
        followers = followers_array.sort_by { |f| f.id }
        klass_records = klass.where(id: followers.map(&:id)).sort_by { |f| f.id }

        if followers.size != klass_records.size
          puts "#{Time.zone.now}: #{followers.first.id} - #{followers.last.id} Record size is invalid."
          failed = true
          break
        end

        if followers.zip(klass_records).any? { |f, tf| attrs.any? { |attr| f.send(attr) != tf.send(attr) } }
          puts "#{Time.zone.now}: #{followers.first.id} - #{followers.last.id} Record content is invalid."
          failed = true
          break
        end

        break if sigint

        puts "#{Time.zone.now}: #{followers.first.id} - #{followers.last.id} OK"
      end
    end

    puts "verify #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, total: #{(Time.zone.now - start_time).round(1)} seconds"
  end

  desc 'benchmark'
  task benchmark: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'followers'
    eval("class #{table.classify} < ActiveRecord::Base; end")
    klass = table.classify.constantize

    Rails.logger.silence do
      num = ENV['NUM'].nil? ? 1000 : ENV['NUM'].to_i
      max = ENV['MAX'].nil? ? klass.maximum(:id) : ENV['MAX'].to_i
      min = ENV['MIN'].nil? ? klass.minimum(:id) : ENV['MIN'].to_i
      from_ids = (min..max).to_a.sample(num)

      start = Time.zone.now
      from_ids.each {|from_id| Follower.where(from_id: from_id).to_a }
      time1 = Time.zone.now - start

      start = Time.zone.now
      from_ids.each {|from_id| klass.where(from_id: from_id).to_a }
      time2 = Time.zone.now - start

      puts ''
      puts 'benchmark summary:'
      puts "  num: #{num}, min: #{min}, max: #{max}, id_min: #{from_ids.min}, id_max: #{from_ids.max}"
      puts "#{Follower.table_name}:"
      puts "  max_id: #{Follower.maximum(:id)}, #{time1} seconds"
      puts "#{klass.table_name}:"
      puts "  max_id: #{klass.maximum(:id)}, #{time2} seconds"
    end
  end
end