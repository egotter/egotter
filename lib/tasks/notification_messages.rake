namespace :notification_messages do
  desc 'add medium'
  task add_medium: :environment do
    ActiveRecord::Base.connection.execute("ALTER TABLE notification_messages ADD medium varchar(191) not null default '' AFTER message")
  end
end
