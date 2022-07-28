namespace :twitter_db do
  namespace :queued_users do
    task delete: :environment do
      TwitterDB::QueuedUser.delete_stale_records
    end

    task consume_scheduled_jobs: :environment do |task|
      worker_class = ImportTwitterDBUserWorker
      limit = 100
      processed_count = 0

      ss = Sidekiq::ScheduledSet.new
      jobs = ss.scan(worker_class.name).select { |job| job.klass == worker_class.name }

      jobs.each do |job|
        worker_class.new.perform(*job.args)
        job.delete

        if (processed_count += 1) >= limit
          break
        end
      end

      puts "#{task.name}: processed_count=#{processed_count}"
    end
  end
end
