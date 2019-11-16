namespace :efs do
  namespace :twitter_users do
    desc 'Import Efs::TwitterUser'
    task import_from_s3: :environment do
      sigint = Util::Sigint.new.trap

      start_id = ENV['START_ID']

      start = Time.zone.now
      processed = 0
      TwitterUser.where("id >= #{start_id}").select(:id).find_each do |user|
        Rails.logger.silence do
          Efs::TwitterUser.import_from_s3!(user.id, skip_if_found: true)
        rescue TypeError => e
          puts e.message
          raise unless e.message == 'Nil is not a valid JSON source.'
        end

        processed += 1
        if processed % 100 == 0
          elapsed = Time.zone.now - start
          puts "#{Time.zone.now} Id #{user.id} Processed #{processed} Elapsed #{elapsed.to_i} sec Avg #{elapsed / processed} sec"
        end

        if sigint.trapped?
          puts "#{user.id}"
          break
        end
      end
    end
  end
end
