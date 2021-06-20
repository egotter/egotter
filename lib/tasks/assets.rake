namespace :assets do
  desc 'Synchronize assets to remote (assumes assets are already compiled)'
  task :sync => :environment do
    # Specify --size-only or --exact-timestamps
    puts %x(aws s3 sync --size-only #{'--delete' if ENV['DELETE']} --exclude 'assets/.sprockets-manifest-*' --acl public-read public s3://egotter-assets/)
  end

  namespace :sync do
    task :download => :environment do
      puts %x(aws s3 sync --size-only --exclude 'assets/.sprockets-manifest-*' --acl public-read s3://egotter-assets/ public)
    end
  end
end

if Rails.env.production?
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["assets:sync"].invoke
  end
end
