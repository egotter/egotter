namespace :delete_unnecessary_statuses_and_favorites do
  desc 'Delete unnecessary statuses and _favorites'
  task run: :environment do
    DeleteUnnecessaryStatusesAndFavorites.new.run
  end
end
