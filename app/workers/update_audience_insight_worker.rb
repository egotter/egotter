class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(uid, options = {})
    logger.info "Timeout #{timeout_in} #{uid} #{options}"

    QueueingRequests.new(self.class).delete(uid)
    RunningQueue.new(self.class).delete(uid)
    UpdateAudienceInsightWorker.perform_in(retry_in, uid, options)
  end

  def retry_in
    60 + rand(120)
  end

  def expire_in
    10.minute
  end

  # options:
  #   enqueued_at
  #   location
  #   twitter_user_id
  def perform(uid, options = {})
    Timeout.timeout(self.timeout_in.seconds) do
      do_perform(uid)
    end
  rescue Timeout::Error => e
    logger.warn "#{e.class}: #{e.message} #{uid} #{options}"
    logger.info e.backtrace.join("\n")
  rescue ActiveRecord::RecordNotUnique => e
    logger.info "#{e.class}: #{e.message} #{uid} #{options}"
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid} #{options}"
    logger.info e.backtrace.join("\n")
  end

  def do_perform(uid, dry_run: false)
    insight = AudienceInsight.find_or_initialize_by(uid: uid)
    return if insight.fresh?

    chart_builder = AudienceInsightChartBuilder.new(uid, limit: 100)

    AudienceInsight::CHART_NAMES.each do |chart_name|
      insight.send("#{chart_name}_text=", chart_builder.send(chart_name).to_json)
    end

    insight.save! unless dry_run
  end
end
