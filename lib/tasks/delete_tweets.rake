namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    if ENV['KEY'] && ENV['BUCKET']
      region = ENV['REGION'] || 'ap-northeast-1'
      bucket = ENV['BUCKET']
      key = ENV['KEY']

      s3 = Aws::S3::Resource.new(region: region).bucket(bucket)
      obj = s3.object(key)

      ENV['SINCE'] = "#{obj.metadata['since']} JST" if obj.metadata['since']
      ENV['UNTIL'] = "#{obj.metadata['until']} JST" if obj.metadata['until']
      puts "since=#{ENV['SINCE']} until=#{ENV['UNTIL']}"
    end

    options = {
        sync: ENV['SYNC'],
        dry_run: ENV['DRY_RUN'],
        since: ENV['SINCE'],
        _until: ENV['UNTIL'],
        threads: ENV['THREADS'],
    }

    task = StartDeletingTweetsTask.new(ENV['SCREEN_NAME'], ENV['FILE'], **options)
    task.start!
  end

  task send_dm: :environment do
    screen_name = ENV['SCREEN_NAME']
    request_id = ENV['REQUEST_ID'] || 'auto'
    dry_run = ENV['DRY_RUN']

    if (user = User.find_by(screen_name: screen_name))
      if request_id == 'auto'
        request = DeleteTweetsByArchiveRequest.order(created_at: :desc).find_by(user_id: user.id)
      else
        request = DeleteTweetsByArchiveRequest.find_by(id: request_id, user_id: user.id)
      end
      puts "request_id=#{request.id}"

      report = DeleteTweetsReport.delete_completed_message(user, request.deletions_count)
      report.deliver! unless dry_run
      puts report.message
    else
      puts 'User not found'
    end
  end

  desc 'Download archive'
  task download_archive: :environment do
    require_relative '../../bin/download_archive'
    main
  end
end
