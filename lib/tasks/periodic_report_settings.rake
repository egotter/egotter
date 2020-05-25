namespace :periodic_report_settings do
  desc 'Create'
  task create: :environment do
    sigint = Util::Sigint.new.trap

    start = ENV['START'] ? ENV['START'].to_i : 1
    processed_count = 0
    created_count = 0

    User.select(:id).find_in_batches(start: start, batch_size: 1000) do |users|
      settings = PeriodicReportSetting.select(:id, :user_id).where(user_id: users.map(&:id)).index_by(&:user_id)
      users.each do |user|
        unless settings[user.id]
          user.create_periodic_report_setting!
          created_count += 1
        end
      end

      processed_count += users.size
      puts "#{Time.zone.now.to_s} first_id=#{users.first.id} last_id=#{users.last.id} processed=#{processed_count} created=#{created_count}"

      if sigint.trapped?
        break
      end
    end
  end
end
