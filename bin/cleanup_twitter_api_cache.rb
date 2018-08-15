require 'twitter_with_auto_pagination'
require 'dotenv/load'

dir = ENV['TWITTER_CACHE_DIR']
start = Time.now
before = %x(du -sh #{dir} | awk '{ print $1 }').chomp

TwitterWithAutoPagination::Client.new(cache_dir: dir).cache.cleanup

after = %x(du -sh #{dir} | awk '{ print $1 }').chomp
elapsed = (Time.now - start).round(3)

puts "#{Time.now.utc} #{$0} #{before} -> #{after} (#{elapsed}sec)"
