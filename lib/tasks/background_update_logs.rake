namespace :background_update_logs do
  desc 'add user_id'
  task add_user_id: :environment do
    ActiveRecord::Base.connection.execute("ALTER TABLE background_update_logs ADD user_id INT(11) NOT NULL DEFAULT -1 AFTER id")
  end
end
