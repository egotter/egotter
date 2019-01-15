ActiveRecord::Base.connection.execute('truncate table twitter_users')
ActiveRecord::Base.connection.execute('truncate table search_histories')

ActiveRecord::Base.connection.execute('set foreign_key_checks = 0')
ActiveRecord::Base.connection.execute('truncate table twitter_db_friendships')
ActiveRecord::Base.connection.execute('truncate table twitter_db_followerships')
ActiveRecord::Base.connection.execute('truncate table twitter_db_users')
ActiveRecord::Base.connection.execute('set foreign_key_checks = 1')

dir = ENV['TWITTER_CACHE_DIR']
TwitterWithAutoPagination::Client.new(cache_dir: dir).cache.clear
