namespace :twitter do
  desc 'cleanup'
  task cleanup: :environment do
    ApiClient.instance.cache.cleanup
  end
end
