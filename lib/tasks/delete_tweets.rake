namespace :delete_tweets do
  task start: :environment do
    if ENV['KEY']
      region = ENV['REGION'] || 'ap-northeast-1'
      bucket = S3::ArchiveData.delete_tweets_bucket_name
      key = ENV['KEY']

      s3 = Aws::S3::Resource.new(region: region).bucket(bucket)
      obj = s3.object(key)

      ENV['SINCE'] = "#{obj.metadata['since']} JST" if obj.metadata['since'].present?
      ENV['UNTIL'] = "#{obj.metadata['until']} JST" if obj.metadata['until'].present?
    end

    if ENV['SCREEN_NAME']
      screen_name = ENV['SCREEN_NAME']
    else
      screen_name = User.find_by(uid: ENV['KEY'].split('-')[0]).screen_name
    end

    unless ENV['FILE']
      raise 'Specify both KEY and FILE' unless ENV['KEY']
      dir = "/efs/lambda_production/#{ENV['KEY']}"
      raise 'Could not find the extracted directory' unless Dir.exist?(dir)
      files = Dir.glob("#{dir}/tweet*.js")
      raise 'Could not find the extracted file(s)' if files.blank?
      ENV['FILE'] = files.join(',')
      puts "files=#{ENV['FILE']}"
    end

    options = {
        dry_run: ENV['DRY_RUN'],
        since: ENV['SINCE'],
        _until: ENV['UNTIL'],
        threads: ENV['THREADS'],
    }

    puts options.inspect
    puts 'Continue?'

    if STDIN.gets.chomp == 'YES'
      task = DeleteTweetsByArchiveTask.new(screen_name, ENV['FILE'], **options)
      task.start
    end
  end

  desc 'Download archive'
  task download_archive: :environment do
    require_relative '../../bin/download_archive'
    main
  end
end
