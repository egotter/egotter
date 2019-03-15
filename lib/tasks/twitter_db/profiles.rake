namespace :twitter_db do
  namespace :profiles do
    desc 'copy'
    task copy: :environment do
      sigint = Util::Sigint.new.trap
      start_time = Time.zone.now
      start = ENV['START'] ? ENV['START'].to_i : 1

      profiles = []
      processed_count = 0

      TwitterDB::User.find_each(start: start, batch_size: 1000).each do |user|
        profiles << TwitterDB::Profile.build_by(user: user)
        processed_count += 1

        if profiles.size >= 1000
          TwitterDB::Profile.import! profiles, validate: false
          profiles.clear
        end

        puts "#{Time.zone.now} #{processed_count} #{sprintf('%.3f', (Time.zone.now - start_time) / processed_count)}" if processed_count % 10000 == 0

        if sigint.trapped?
          puts "id #{user.id}"
          break
        end
      end
    end
  end
end
