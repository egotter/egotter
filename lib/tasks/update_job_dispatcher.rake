namespace :update_job_dispatcher do
  desc 'Dispatch TwitterUserUpdateJob'
  task run: :environment do
    puts "[#{Time.now}] enqueue start"

    # TODO use queue priority
    # TODO check the case in which search log exists but TwitterUser don't exist

    # TODO reject too many friends and followers

    key = 'update_job_dispatcher:recently_added'
    rem_count = redis.zremrangebyscore(key, 0, 2.days.ago.to_i)
    encueue_count = 0
    encueue_uids = []

    begin
      uids = client.follower_ids('ego_tter').map{|id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      logger.warn "#{bot.uid} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
      next
    end

    uids.shuffle.each do |uid|
      if redis.zrank(key, uid.to_s).nil?
        if !TwitterUser.exists?(uid: uid.to_i) || !TwitterUser.find_by(uid: uid.to_i).recently_updated?
          TwitterUserUpdaterWorker.perform_async(uid.to_i)
          encueue_uids << uid.to_i
        end
        redis.zadd(key, now_i, uid.to_s)
        encueue_count += 1
      end

      break if encueue_count >= 20
    end


    puts "[#{Time.now}] enqueue finish rem=#{rem_count} encueue=#{encueue_count} #{encueue_uids.join(',')}"
  end

  def now_i
    Time.zone.now.to_i
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def client
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: bot.token,
      access_token_secret: bot.secret
    }
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

  def bot
    raise 'create bot' if Bot.empty?
    @bot ||= Bot.sample
  end
end
