namespace :zadd_well_known_errors do
  desc 'Zadd well known errors'
  task run: :environment do
    start_t = Time.zone.now

    too_many_friends_key = Redis.background_update_worker_too_many_friends_key
    unauthorized_key = Redis.background_update_worker_unauthorized_key

    target_user = ENV['user'].nil? ? 'ego_tter' : ENV['user']
    begin
      follower_uids = client.follower_ids(target_user).map { |id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      end_t = Time.zone.now
      puts "#{client.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds (#{end_t - start_t}s)"
      next
    end

    target_uids = follower_uids.select do |uid|
      redis.zrank(too_many_friends_key, uid.to_s).blank? &&
        redis.zrank(unauthorized_key, uid.to_s).blank?
    end

    zadd_count = 0
    target_uids.each_slice(100).each do |uids|
      users = client.users(uids)
      users.each do |user|
        tu = TwitterUser.build_by_user(user, build_relation: false)

        if tu.too_many_friends?
          redis.zadd(too_many_friends_key, now_i, tu.uid.to_s)
          zadd_count += 1
        elsif tu.unauthorized?
          redis.zadd(unauthorized_key, now_i, tu.uid.to_s)
          zadd_count += 1
        end
      end
    end

    puts "client=#{client.screen_name} user=#{target_user} count=#{zadd_count} #{Time.zone.now - start_t}s"
  end

  def now_i
    Time.zone.now.to_i
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def client
    @client ||= Bot.api_client
  end
end
