namespace :zadd_well_known_errors do
  desc 'Zadd well known errors'
  task run: :environment do
    start_t = Time.zone.now

    target_user = ENV['user'].nil? ? 'ego_tter' : ENV['user']
    begin
      follower_uids = client.follower_ids(target_user).map { |id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      end_t = Time.zone.now
      puts "#{client.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds (#{end_t - start_t}s)"
      next
    end

    target_uids = follower_uids.select do |uid|
      redis.zrank(TooManyFriendsUidList.key, uid.to_s).blank? &&
        redis.zrank(UnauthorizedUidList.key, uid.to_s).blank?
    end

    zadd_count = 0
    target_uids.each_slice(100).each do |uids|
      users = client.users(uids)
      users.each do |user|
        # TODO Maybe this code causes too many requests error.
        tu = TwitterUser.build_without_relations(client, user.id, -1)

        if tu.too_many_friends?
          redis.zadd(TooManyFriendsUidList.key, now_i, tu.uid.to_s)
          zadd_count += 1
        elsif tu.unauthorized_job?
          redis.zadd(UnauthorizedUidList.key, now_i, tu.uid.to_s)
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
    @redis ||= Redis.client
  end

  def client
    @client ||= Bot.api_client
  end
end
