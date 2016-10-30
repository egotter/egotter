namespace :logs do
  desc 'fill referral'
  task fill_referral: :environment do
    Rails.logger.silence do
      [BackgroundSearchLog, SignInLog, SearchLog, ModalOpenLog].each do |klass|
        puts "\n#{Time.zone.now}: #{klass} started."
        klass.find_each(batch_size: 1000) do |log|
          log.update_column(:referral, log.channel)
        end
        puts "#{Time.zone.now}: #{klass} finished."
      end
    end
  end
end