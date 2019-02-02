namespace :caches do
  desc 'cleanup'
  task cleanup: :environment do
    Benchmark.bm(35) do |r|
      [Rails.cache, KloutClient.new, ApiClient.instance.cache].each do |obj|
        r.report(obj.class.name) { obj.cleanup }
      end
    end
  end
end
