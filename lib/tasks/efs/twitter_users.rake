namespace :efs do
  namespace :twitter_users do
    desc 'Import Efs::TwitterUser'
    task import_from_s3: :environment do
      sigint = Util::Sigint.new.trap

      start_id = (ENV['START_ID'] || 1).to_i
      threads = (ENV['THREADS'] || 100).to_i

      # Avoid LoadError
      Efs::TwitterUser
      Efs::TwitterUser.cache_client
      CacheDirectory
      S3::Profile
      S3::Friendship
      S3::Followership

      start = Time.zone.now
      processed = 0
      TwitterUser.where("id >= #{start_id}").select(:id, :uid, :screen_name).find_in_batches(batch_size: 1000) do |users_array|
        Parallel.each(users_array, in_threads: threads) do |user|
          Rails.logger.silence do
            Efs::TwitterUser.import_from_s3!(user, skip_if_found: true)
          rescue TypeError => e
            puts "#{e.message} #{user.id}"
            raise unless e.message == 'Nil is not a valid JSON source.'
          end
        end

        processed += users_array.size
        elapsed = Time.zone.now - start
        puts "#{Time.zone.now} Id #{users_array.last.id} Processed #{processed} Elapsed #{elapsed.to_i} sec Avg #{sprintf('%.3f', elapsed / processed)} sec"

        break if sigint.trapped?
      end
    end
  end
end
