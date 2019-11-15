bots =
    JSON.parse(File.read('new_bot.json'), symbolize_names: true).map do |attrs|
      Bot.new(attrs.slice(:uid, :screen_name, :token, :secret))
    end

Bot.transaction {Bot.import! bots}

CacheDirectory.create(name: 'twitter', dir: 'tmp/twitter_cache_xxxx')
CacheDirectory.create(name: 's3', dir: 'tmp/s3_cache')
CacheDirectory.create(name: 'efs_twitter_user', dir: 'tmp/efs_twitter_user_cache_xxxx')


dir = CacheDirectory.find_by(name: 'twitter')&.dir || ENV['TWITTER_CACHE_DIR']
ApiClient.instance(cache_dir: dir).cache.clear

Redis.client.flushdb
