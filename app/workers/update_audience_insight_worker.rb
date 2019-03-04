class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def timeout_in
    10.second
  end

  def retry_in
    60 + rand(120)
  end

  def expire_in
    10.minute
  end

  def perform(uid, options = {})
    insight = AudienceInsight.find_or_initialize_by(uid: uid)
    return if insight.fresh?

    chart_builder = AudienceInsightChartBuilder.new(uid, limit: 100)

    AudienceInsight::CHART_NAMES.each do |chart_name|
      insight.send("#{chart_name}_text=", chart_builder.send(chart_name).to_json)
    end

    insight.save!
  rescue ActiveRecord::RecordNotUnique => e
    logger.info "#{e.class}: #{e.message} #{uid}"
    logger.info e.backtrace.join("\n")
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid}"
    logger.info e.backtrace.join("\n")
  end
end
