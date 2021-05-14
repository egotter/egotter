namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    options = {
        sync: ENV['SYNC'],
        dry_run: ENV['DRY_RUN'],
        since: ENV['SINCE'],
        _until: ENV['UNTIL']
    }
    task = StartDeletingTweetsTask.new(ENV['SCREEN_NAME'], ENV['FILE'], **options)
    task.start!
  end

  task send_dm: :environment do
    screen_name = ENV['SCREEN_NAME']
    request_id = ENV['REQUEST_ID']

    if (user = User.find_by(screen_name: screen_name))
      report = DeleteTweetsReport.delete_completed_message(user, request_id)
      report.deliver!
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
