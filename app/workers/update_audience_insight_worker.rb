class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    10.minute
  end

  def timeout_in
    20.seconds
  end

  def after_timeout(uid, options = {})
    logger.warn "Timeout #{timeout_in} #{uid} #{options}"
    UpdateAudienceInsightWorker.perform_in(retry_in, uid, options)
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
    insight = AudienceInsight.find_or_initialize_by(uid: uid)
    return if insight.fresh?

    chart_builder = AudienceInsightChartBuilder.new(uid, limit: 100)

    AudienceInsight::CHART_NAMES.each do |chart_name|
      insight.send("#{chart_name}_text=", chart_builder.send(chart_name).to_json)
    end

    insight.save!

  rescue ActiveRecord::RecordNotUnique => e
    logger.info "#{e.class}: #{e.message} #{uid} #{options}"
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid} #{options}"
    logger.info e.backtrace.join("\n")
  end
end
