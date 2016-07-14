require 'mixpanel-ruby'

class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  MIXPANEL_TOKEN = ENV['MIXPANEL']

  def perform(attrs)
    log = SearchLog.create!(attrs)

    tracker = Mixpanel::Tracker.new(MIXPANEL_TOKEN)
    tracker.track(log.session_id, log.action, log.attributes)
  rescue => e
    logger.warn "#{e}: #{e.message}"
    logger.warn attrs.inspect
  end
end
