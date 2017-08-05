namespace :klout_client do
  desc 'show_all_values'
  task show_all_values: :environment do
    cache = KloutClient.new.instance_variable_get(:@cache)
    options = cache.send(:merged_options, nil)
    count = 0

    cache.send(:search_dir, cache.cache_path) do |fname|
      key = cache.send(:file_path_key, fname)
      entry = cache.send(:read_entry, key, options)
      puts "#{key} #{entry.value.to_s.truncate(30)}"
      count += 1
    end

    puts "count #{count}"
  end
end
