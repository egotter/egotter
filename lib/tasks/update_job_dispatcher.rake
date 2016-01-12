namespace :update_job_dispatcher do
  desc 'Dispatch TwitterUserUpdateJob'
  task run: :environment do
    puts 'enqueue start'

    # TODO don't enqueue if recently endueued
    # TODO use queue priority
    # TODO check the case in which search log exists but TwitterUser don't exist

    count = 0
    uids = SearchLog.order(created_at: :desc).limit(50).pluck(:search_uid).compact.uniq
    uids.each do |uid|
      # next if uid.recently_added to this queue?
      # next if TwitterUser.find_by(uid: uid).recently_created?
      # next if TwitterUser.find_by(uid: uid).recently_updated?
      TwitterUserUpdaterWorker.perform_async(uid.to_i)
      count += 1
    end
    puts 'enqueue finish ' + count.to_s
  end
end
