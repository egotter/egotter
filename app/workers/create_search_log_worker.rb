class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    log = SearchLog.new(attrs)
    log.assign_attributes(landing: landing_page?(log), first_time: first_time_session?(log))
    log.save!
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end

  private

  def landing_page?(log)
    log.device_type != 'crawler' && log.session_id != '-1' && !log.referer.start_with?('https://egotter.com') &&
      !SearchLog.exists?(session_id: log.session_id, created_at: 30.minutes.ago..log.created_at)
  end

  def first_time_session?(log)
    log.device_type != 'crawler' && log.session_id != '-1' &&
      !SearchLog.exists?(session_id: log.session_id)
  end
end
