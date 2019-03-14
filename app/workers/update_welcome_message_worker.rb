class UpdateWelcomeMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def perform(attrs)
    report = WelcomeMessage.find_by(token: attrs['token'])
    return if report.nil? || report.read?

    if report.created_at < Time.zone.now - 5.seconds
      report.update!(read_at: attrs['read_at'])
    end
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{attrs.inspect}"
  end
end
