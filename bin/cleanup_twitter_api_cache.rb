require 'twitter_friendly'
require 'dotenv/load'

dir = ENV['TWITTER_CACHE_DIR']
start = Time.now
before = %x(du -sh #{dir} | awk '{ print $1 }').chomp

begin
  TwitterFriendly::Client.new(cache_dir: dir).cache.cleanup
rescue => e
  puts "#{Time.now.utc} #{e.class} #{e.message}"
end

after = %x(du -sh #{dir} | awk '{ print $1 }').chomp
elapsed = (Time.now - start).round(3)

puts "#{Time.now.utc} #{$0} #{before} -> #{after} (#{elapsed}sec)"
