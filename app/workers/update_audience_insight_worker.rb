class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.minute
  end

  def _timeout_in
    30.seconds
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

    attrs = AudienceInsight::Builder.new(uid, timeout: 10.minutes, concurrency: 10).build

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
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options}"
      Airbag.info e.backtrace.join("\n")
    end
  end
end
