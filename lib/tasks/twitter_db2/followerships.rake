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
            TwitterDB2::Followership.import(records, on_duplicate_key_update: %i(user_uid follower_uid sequence), vaildate: false, timestamps: false)
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
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      failed = false
      processed = 0
      processed_uids = []
      invalid = []
      puts "\nverify started:"

      Rails.logger.silence do
        TwitterDB::Followership.find_in_batches(start: start, batch_size: batch_size) do |records|
          user_uids = records.map(&:user_uid).uniq.select { |user_uid| processed_uids.exclude? user_uid }
          records2 = TwitterDB2::Followership.where(user_uid: user_uids).to_a

          TwitterDB::Followership.where(user_uid: user_uids).each do |record1|
            record2_index = records2.index { |record| %i(user_uid follower_uid sequence).all? { |attr| record[attr] == record1[attr] } }
            unless record2_index
              invalid << record1.user_uid
              puts "invalid: #{[record1.user_uid, record1.follower_uid, record1.sequence].join(', ')} doesn't exist"
              next
            end
            records2.delete_at(record2_index)
          end

          processed_uids += user_uids
          processed += records.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{records[0].id} - #{records[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "invalid: #{invalid.uniq.inspect}" if invalid.any?
      puts "verify #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end