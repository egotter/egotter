start = Time.now
before = %x(du -sh tmp/api_cache | awk '{ print $1 }').chomp

ApiClient.instance.cache.cleanup

after = %x(du -sh tmp/api_cache | awk '{ print $1 }').chomp
elapsed = (Time.now - start).round(3)

puts "#{Time.now.utc} #{$0} #{before} -> #{after} (#{elapsed}sec)"
