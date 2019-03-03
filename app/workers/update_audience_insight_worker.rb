class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uid, options = {})
    queue = RunningQueue.new(self.class)
    return if !options['skip_queue'] && queue.exists?(uid)
    queue.add(uid)

    if options['enqueued_at'].blank? || Time.zone.parse(options['enqueued_at']) < Time.zone.now - 10.minute
      logger.info {"Don't run this job since it is too late."}
      return
    end

    Timeout.timeout(10) do
      do_perform(uid)
    end
  rescue Timeout::Error => e
    logger.info "#{e.class}: #{e.message} #{uid}"
    logger.info e.backtrace.join("\n")
    self.class.perform_in(600 + rand(120), uid, options)
  end

  def do_perform(uid)
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
