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
    blocked_ids = fetch_blocked_uids(user.api_client.twitter)
    return if blocked_ids.blank?

    BlockingRelationship.import_from(user.uid, blocked_ids)

    blocked_ids.each_slice(100).each do |uids_array|
      CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids_array, user_id: user_id, enqueued_by: self.class)
    end

    blocked_ids.each_slice(1000) do |uids_array|
      User.where(uid: uids_array).each do |user|
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

  private

  def fetch_blocked_uids(client)
    options = {count: 5000, cursor: -1}
    limit = 10000
    call_limit = 2
    call_count = 0
    collection = []

    while true do
      response = client.blocked_ids(options)
      call_count += 1
      break if response.nil?

      collection.concat(response.attrs[:ids])

      if response.attrs[:next_cursor] == 0 || collection.size >= limit || call_count >= call_limit
        break
      end

      options[:cursor] = response.attrs[:next_cursor]
    end

    if collection.size != collection.uniq.size
      logger.warn "#{__method__}: uids is not unique"
      collection.uniq!
    end

    collection
  end
end
