namespace :cache_directories do
  desc 'Rotate'
  task rotate: :environment do
    CacheDirectory.find_by(name: 'twitter').rotate!
  end
end
