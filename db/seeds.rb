bots =
    JSON.parse(File.read('new_bot.json'), symbolize_names: true).map do |attrs|
      Bot.new(attrs.slice(:uid, :screen_name, :token, :secret))
    end

Bot.transaction {Bot.import! bots}

dir = ENV['TWITTER_CACHE_DIR']
ApiClient.instance(cache_dir: dir).cache.clear

Redis.client.flushdb
