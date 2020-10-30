class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.minute
  end

  # Handle timeout by myself
  def _timeout_in
    10.seconds
  end

  def after_timeout(*args)
    logger.info { "Timeout seconds=#{_timeout_in} args=#{args.inspect}" }
    UpdateAudienceInsightWorker.perform_in(retry_in, *args)
  end

  def retry_in
    unique_in + rand(120)
  end

  def expire_in
    10.minute
  end

  # options:
  #   location
  #   twitter_user_id
  def perform(uid, options = {})
    insight = AudienceInsight.find_or_initialize_by(uid: uid) # TODO Select only specific columns
    return if insight.fresh?

    timeout_handler = Proc.new { |records_size| after_timeout(uid, {records_size: records_size}.merge(options)) }
    attrs = AudienceInsight::Builder.new(uid, timeout: _timeout_in, concurrency: 1, timeout_handler: timeout_handler).build

    if attrs.any?
      insight.assign_attributes(attrs)
      insight.save! if insight.changed?
    end
  rescue => e
    handle_exception(e, uid, options)
  end

  def handle_exception(e, uid, options)
    if e.class == ActiveRecord::RecordNotUnique
      # Do nothing
    else
      logger.warn "#{e.inspect} uid=#{uid} options=#{options}"
      logger.info e.backtrace.join("\n")
    end
  end
end
