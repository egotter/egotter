namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    options = {
        sync: ENV['SYNC'],
        dry_run: ENV['DRY_RUN'],
        since: ENV['SINCE'],
        until: ENV['UNTIL']
    }
    task = StartDeletingTweetsTask.new(ENV['SCREEN_NAME'], ENV['FILE'], **options)
    task.start!
  end

  desc 'Download archive'
  task download_archive: :environment do
    require_relative '../../bin/download_archive'
    main
  end
end
