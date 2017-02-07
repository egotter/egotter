namespace :twitter_db2 do
  namespace :followerships do
    desc 'copy from TwitterDB::Followership to TwitterDB2::Followership'
    task copy: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 10000
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\ncopy started:"

      Rails.logger.silence do
        TwitterDB::Followership.find_in_batches(start: start, batch_size: batch_size) do |records|
          begin
            TwitterDB2::Followership.import(records, on_duplicate_key_update: %i(id), vaildate: false, timestamps: false)
          rescue => e
            puts "#{e.class} #{e.message.slice(0, 100)}"
            failed = true
          end

          processed += records.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{records[0].id} - #{records[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end

    desc 'verify TwitterDB2::Followership'
    task verify: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 10000
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\nverify started:"

      Rails.logger.silence do
        TwitterDB::Followership.find_in_batches(start: start, batch_size: batch_size) do |records|
          records2 = TwitterDB2::Followership.where(user_uid: records.map(&:user_uid))
          records.each do |record1|
            record2 = records2.find { |record| %i(user_uid follower_uid sequence).all? { |attr| record[attr] == record1[attr] } }
            unless record2
              puts "invalid: #{[record1.user_uid, record1.follower_uid, record1.sequence].join(', ')} doesn't exist"
              next
            end
          end

          processed += records.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{records[0].id} - #{records[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "verify #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end