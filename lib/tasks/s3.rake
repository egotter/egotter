namespace :s3 do
  desc 'Find broken data'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    logger = TaskLogger.logger('log/s3_check.log')
    Rails.logger = logger

    start_id = ENV['START'] ? ENV['START'].to_i : 1
    start = Time.zone.now
    processed_count = 0
    found_ids = []

    logger.info TwitterUser.new.s3_need_fix_headers.join(', ')

    (start_id..(TwitterUser.maximum(:id))).each do |twitter_user_id|
      logger.info "#{twitter_user_id} #{(Time.zone.now - start) / processed_count}" if processed_count % 1000 == 0
      processed_count += 1

      user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find_by(id: twitter_user_id)
      next unless user

      if logger.silence { user.s3_need_fix? }
        found_ids << user.id
        logger.info "#{user.id} #{(user.s3_need_fix_reasons).inspect}"
      end

      break if sigint.trapped?
    end

    logger.info found_ids.join(',') if found_ids.any?

    logger.info Time.zone.now - start
  end
end
