namespace :notification_settings do
  desc 'backup'
  task backup: :environment do
    ActiveRecord::Base.connection.execute("CREATE TABLE old_notification_settings LIKE notification_settings")
    ActiveRecord::Base.connection.execute("INSERT INTO old_notification_settings SELECT * FROM notification_settings")
  end

  desc 'migrate'
  task migrate: :environment do
    settings = NotificationSetting.all
    settings.each do |s|
      s.updated = s.dm
      s.search_sent_at = s.last_search_at
      s.update_sent_at = s.last_dm_at
      # last_email_at is not used
    end
    NotificationSetting.import settings, validate: false, timestamps: false
  end
end
