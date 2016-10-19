namespace :search_logs do
  desc 'add medium'
  task add_medium: :environment do
    ActiveRecord::Base.connection.execute("ALTER TABLE search_logs ADD medium varchar(191) not null default '' AFTER channel")
  end
end
