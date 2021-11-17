namespace :assets do
  desc 'Upload assets to S3'
  task :upload => :environment do
    puts %x(aws s3 sync --size-only --exclude 'assets/.sprockets-manifest-*' --acl public-read public s3://egotter-assets/)
  end

  desc 'Download assets from S3'
  task :download => :environment do
    puts %x(aws s3 sync --size-only --exclude 'assets/.sprockets-manifest-*' --acl public-read s3://egotter-assets/ public)
  end
end
