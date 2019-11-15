namespace :cache_directories do
  desc 'Rotate'
  task rotate: :environment do
    CacheDirectory.find_by(name: 'twitter').rotate!
    # CacheDirectory.find_by(name: 'efs_twitter_user').rotate!
  end
end
