namespace :twitter_db do
  namespace :queued_users do
    task delete: :environment do
      TwitterDB::QueuedUser.delete_stale_records
    end
  end
end
