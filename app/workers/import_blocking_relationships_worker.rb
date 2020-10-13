class ImportBlockingRelationshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    begin
      blocked_ids = user.api_client.twitter.blocked_ids(count: 5000).attrs[:ids]
      BlockingRelationship.import_from(user.uid, blocked_ids)
    rescue => e
      if AccountStatus.invalid_or_expired_token?(e) ||
          AccountStatus.temporarily_locked?(e)
        # Do nothing
      else
        raise
      end
    end
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
