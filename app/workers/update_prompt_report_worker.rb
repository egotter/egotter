class UpdatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(attrs)
    report = PromptReport.find_by(token: attrs['token'])
    return if report.nil? || report.read?
    report.update!(read_at: attrs['read_at'])
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{attrs.inspect}"
  end
end
