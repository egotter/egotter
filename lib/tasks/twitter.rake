namespace :twitter do
  desc 'cleanup'
  task cleanup: :environment do
    Twitter::REST::Client.new.cache.cleanup
  end
end
