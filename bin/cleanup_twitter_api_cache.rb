require 'timeout'
require 'twitter_with_auto_pagination'
require 'dotenv/load'

dir = ENV['TWITTER_CACHE_DIR']
start = Time.now
before = %x(du -sh #{dir} | awk '{ print $1 }').chomp

begin
  Timeout.timeout(600) do
    # Can't use ApiClient because the context is ruby
    TwitterWithAutoPagination::Client.new(cache_dir: dir).cache.cleanup
  end
rescue Timeout::Error => e
  puts "#{Time.now.utc} #{e.class} #{e.message}"
rescue => e
  puts "#{Time.now.utc} #{e.class} #{e.message}"
end

after = %x(du -sh #{dir} | awk '{ print $1 }').chomp
elapsed = (Time.now - start).round(3)

puts "#{Time.now.utc} #{$0} #{before} -> #{after} (#{elapsed}sec)"
