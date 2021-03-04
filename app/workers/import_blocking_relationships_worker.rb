class ImportBlockingRelationshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.minutes
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    collected_uids = BlockingRelationship.collect_uids(user.id)
    return if collected_uids.blank?

    BlockingRelationship.import_from(user.uid, collected_uids)

    collected_uids.each_slice(100).each do |uids_array|
      CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids_array, user_id: user_id, enqueued_by: self.class)
    end

    collected_uids.each_slice(1000) do |uids_array|
      User.authorized.where(uid: uids_array).each do |user|
        CreateBlockReportWorker.perform_in(rand(30).minutes, user.id)
      end
    end
  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.temporarily_locked?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect.truncate(200)} user_id=#{user_id} options=#{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end
