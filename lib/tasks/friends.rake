namespace :friends do
  desc 'reset'
  task reset: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table}")
    ActiveRecord::Base.connection.execute("CREATE TABLE #{table} like friends")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP updated_at")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} ROW_FORMAT = COMPRESSED")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} KEY_BLOCK_SIZE = 4")
  end

  desc 'drop_index'
  task drop_index: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_friends_on_uid")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_friends_on_from_id")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_friends_on_screen_name")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DROP INDEX index_friends_on_created_at")
  end

  desc 'add_index'
  task add_index: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    # ActiveRecord::Base.connection.execute("CREATE INDEX index_friends_on_uid ON #{table} (uid)")
    ActiveRecord::Base.connection.execute("CREATE INDEX index_friends_on_from_id ON #{table} (from_id)")
    # ActiveRecord::Base.connection.execute("CREATE INDEX index_friends_on_screen_name ON #{table} (screen_name)")
    # ActiveRecord::Base.connection.execute("CREATE INDEX index_friends_on_created_at ON #{table} (created_at)")
  end

  desc 'rename'
  task rename: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    ActiveRecord::Base.connection.execute('ALTER TABLE friends RENAME old_friends')
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} RENAME friends")
  end

  desc 'copy'
  task copy: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
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

    Rails.logger.silence do
      Friend.find_in_batches(start: start, batch_size: 5000) do |friends_array|
        friends = friends_array.map do |f|
          [f.id, f.uid, f.screen_name, f.user_info, f.from_id, f.created_at]
        end

        begin
          klass.import(%i(id uid screen_name user_info from_id created_at), friends, validate: false)
          puts "#{Time.zone.now}: #{friends.first[0]} - #{friends.last[0]}"
        rescue => e
          puts "#{e.class} #{e.message.slice(0, 100)}"
          failed = true
        end

        break if sigint || failed
      end
    end

    puts (sigint || failed ? 'suspended:' : 'finished:')
    puts "  start: #{start}, #{(Time.zone.now - start_time)} seconds"
  end

  desc 'verify'
  task verify: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    eval("class #{table.classify} < ActiveRecord::Base; end")
    klass = table.classify.constantize

    Rails.logger.silence do
      num = ENV['NUM'].nil? ? 1000 : ENV['NUM'].to_i
      max = ENV['MAX'].nil? ? 1000 : ENV['MAX'].to_i
      min = ENV['MIN'].nil? ? 1 : ENV['MIN'].to_i
      rnd = ENV['RND'].nil? ? false : true
      slice_size = ENV['SLICE'].nil? ? 1000 : ENV['SLICE'].to_i
      ids =
        if rnd
          random = Random.new; range = min..max
          num.times.map { random.rand(range) }.uniq
        else
          (min..max).to_a.slice(0, num)
        end

      sql = <<-"SQL".strip_heredoc
        SELECT a.id
        FROM (
          SELECT id, uid, screen_name, from_id, created_at FROM friends WHERE id IN (:ids)
        ) a JOIN (
          SELECT id, uid, screen_name, from_id, created_at FROM #{table} WHERE id IN (:ids)
        ) b ON (a.id = b.id)
        WHERE a.uid = b.uid AND a.screen_name = b.screen_name AND a.from_id = b.from_id AND a.created_at = b.created_at
      SQL

      match_count = 0
      not_match_ids = []
      begin
        ids.each_slice(slice_size).each do |ids_array|
          matched_ids = Friend.find_by_sql([sql, ids: ids_array]).map(&:id)
          not_match_ids += (ids_array - matched_ids) if (ids_array - matched_ids).any?
          match_count += matched_ids.size
          print '.'
        end
        puts ''
      rescue => e
        puts "#{e.class} #{e.message.slice(0, 100)}"
      end

      user_info_match_count = 0
      begin
        (ids - not_match_ids).sample(slice_size).each do |id|
          result = Friend.find(id).user_info == klass.find(id).user_info
          user_info_match_count += 1 if result
          print '.'
        end
        puts ''
      rescue => e
        puts "#{e.class} #{e.message.slice(0, 100)}"
      end

      sql = <<-"SQL".strip_heredoc
        SELECT auto_increment at
        FROM information_schema.tables
        WHERE table_schema = "egotter_#{Rails.env}" AND table_name = :table
      SQL

      puts ''
      puts 'Summary:'
      puts "  num: #{num}, min: #{min}, max: #{max}, rnd: #{rnd}, slice: #{slice_size}, uniq_id: #{ids.size}, match: #{match_count} user_info_match(#{slice_size}): #{user_info_match_count}, id_min: #{ids.min}, id_max: #{ids.max}"
      puts "#{Friend.table_name}:"
      puts "  id_max: #{Friend.all.maximum(:id)}, auto_increment: #{Friend.find_by_sql([sql, table: :friends]).first.at}, match: #{Friend.where(id: ids).count}"
      puts "#{klass.table_name}:"
      puts "  id_max: #{klass.all.maximum(:id)}, auto_increment: #{klass.find_by_sql([sql, table: table]).first.at}, match: #{klass.where(id: ids).count}"
      if not_match_ids.any?
        puts 'not match:'
        puts "  size: #{not_match_ids.size}, ids: #{not_match_ids.slice(0, 100).join(', ')}"
      end

      File.write("#{Rails.root}/ids.txt", ids.sort.join("\n"))
    end
  end

  desc 'benchmark'
  task benchmark: :environment do
    table = ENV['TABLE']
    raise 'Specify table name.' if table.blank? || table == 'friends'
    eval("class #{table.classify} < ActiveRecord::Base; end")
    klass = table.classify.constantize

    Rails.logger.silence do
      num = ENV['NUM'].nil? ? 1000 : ENV['NUM'].to_i
      max = ENV['MAX'].nil? ? 1000 : ENV['MAX'].to_i
      min = ENV['MIN'].nil? ? 1 : ENV['MIN'].to_i
      rnd = ENV['RND'].nil? ? false : true
      from_ids =
        if rnd
          random = Random.new; range = min..max
          num.times.map { random.rand(range) }.uniq
        else
          (min..max).to_a.slice(0, num)
        end

      start = Time.zone.now
      from_ids.each {|id| Friend.where(from_id: id).to_a }
      time1 = Time.zone.now - start

      start = Time.zone.now
      from_ids.each {|id| klass.where(from_id: id).to_a }
      time2 = Time.zone.now - start

      puts ''
      puts 'Summary:'
      puts "  num: #{num}, min: #{min}, max: #{max}, rnd: #{rnd}, id_min: #{from_ids.min}, id_max: #{from_ids.max}"
      puts "#{Friend.table_name}:"
      puts "  max_id: #{Friend.all.maximum(:id)}, #{time1} seconds"
      puts "#{klass.table_name}:"
      puts "  max_id: #{klass.all.maximum(:id)}, #{time2} seconds"
    end
  end
end