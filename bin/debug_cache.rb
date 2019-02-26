require 'dotenv/load'
require 'active_support'

dir = ARGV[0]

cache = ActiveSupport::Cache::FileStore.new(dir, expires_in: 1.second)
key = 'a'

puts %x(ls #{dir})
cache.write(key, 1)
puts cache.exist?(key)
puts cache.read(key)
puts %x(ls #{dir})

sleep 2

puts %x(ls #{dir})
puts cache.read(key)
puts %x(ls #{dir})
