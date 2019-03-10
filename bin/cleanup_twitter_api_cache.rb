require 'timeout'
require 'twitter_with_auto_pagination'
require 'dotenv/load'

def disk_size(dir)
  # %x(du -sh #{dir} | awk '{ print $1 }').chomp
  %x(df -h #{dir} | grep efs | awk '{ print $3 }').chomp
end

dir = CacheDirectory.find_by(name: 'twitter')&.dir || ENV['TWITTER_CACHE_DIR']
start = Time.now
before = disk_size(dir)

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

elapsed = (Time.now - start).round(3)

puts "#{Time.now.utc} #{$0} #{before} -> #{disk_size(dir)} (#{elapsed}sec)"
