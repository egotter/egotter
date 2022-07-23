class UpdatePeriodicReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # attrs:
  #   token
  #   read_at
  def perform(attrs)
    report = PeriodicReport.find_by(token: attrs['token'])
    return if report.nil? || report.read?

    if report.created_at < Time.zone.now - 5.seconds
      report.update!(read_at: attrs['read_at'])
    else
      Airbag.info "Too fast read #{report.id} #{attrs}"
    end
  rescue => e
    Airbag.exception e, attrs: attrs
  end
end
