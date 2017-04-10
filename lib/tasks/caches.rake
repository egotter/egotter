namespace :caches do
  desc 'cleanup'
  task cleanup: :environment do
    Benchmark.bm(35) do |r|
      [Rails.cache, ::Cache::PageCache.new, KloutClient.new, Twitter::REST::Client.new.cache].each do |obj|
        r.report(obj.class.name) { obj.cleanup }
      end
    end
  end
end
