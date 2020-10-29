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
    BlockingRelationship.import_from(user.uid, blocked_ids)
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

    collection
  end
end
