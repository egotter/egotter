namespace :twitter_db do
  namespace :s3 do
    namespace :profiles do
      desc 'Write profiles to S3'
      task write_to_s3: :environment do
        sigint = Util::Sigint.new.trap

        start_id = ENV['START'] ? ENV['START'].to_i : 1
        start = Time.zone.now
        processed_count = 0

        TwitterDB::User.select(:id, :uid, :screen_name, :user_info).find_in_batches(start: start_id, batch_size: 100) do |group|
          TwitterDB::S3::Profile.import!(group)
          processed_count += group.size
          puts "#{now = Time.zone.now} #{group.last.id} #{(now - start) / processed_count}"

          break if sigint.trapped?
        end

        puts Time.zone.now - start
      end
    end
  end
end
