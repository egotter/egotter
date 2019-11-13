namespace :assets do
  desc 'Synchronize assets to remote (assumes assets are already compiled)'
  task :sync => :environment do
    puts %x(aws s3 sync --exact-timestamps #{'--delete' if ENV['DELETE']} --acl public-read public s3://egotter-assets/)
  end
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["assets:sync"].invoke
end
