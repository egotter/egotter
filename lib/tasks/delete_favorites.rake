namespace :delete_favorites do
  task delete_by_archive: :environment do
    options = {
        sync: ENV['SYNC'],
        dry_run: ENV['DRY_RUN'],
    }
    task = StartDeletingFavoritesTask.new(ENV['SCREEN_NAME'], ENV['FILE'], **options)
    task.start!
  end

  task send_dm: :environment do
    screen_name = ENV['SCREEN_NAME']
    request_id = ENV['REQUEST_ID'] || 'auto'
    dry_run = ENV['REQUEST_ID']

    if (user = User.find_by(screen_name: screen_name))
      if request_id == 'auto'
        request_id = DeleteFavoritesRequest.order(created_at: :desc).find_by(user_id: user.id).id
        puts "request_id=#{request_id}"
      end

      report = DeleteFavoritesReport.delete_completed_message(user, request_id)
      report.deliver! unless dry_run
      puts report.message
    else
      puts 'User not found'
    end
  end

  task download_archive: :environment do
    require_relative '../../bin/download_archive'
    main
  end
end
