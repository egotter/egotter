class UpdateSearchReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # attrs:
  #   token
  #   read_at
  def perform(attrs)
    report = SearchReport.find_by(token: attrs['token'])
    return if report.nil? || report.read?

    if report.created_at < Time.zone.now - 5.seconds
      report.update!(read_at: attrs['read_at'])
    else
      logger.info "Too fast read #{report.id} #{attrs}"
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{attrs}"
  end
end
