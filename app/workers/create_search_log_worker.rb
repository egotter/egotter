require 'mixpanel-ruby'
require 'statsd'

class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  MIXPANEL_TOKEN = ENV['MIXPANEL']

  def perform(attrs)
    log = create_log(attrs)
    mixpanel(log)
    data_dog(log)
  end

  def create_log(attrs)
    SearchLog.create!(attrs)
  rescue => e
    logger.warn "#{e}: #{e.message} #{attrs.inspect}"
  end

  def mixpanel(log)
    tracker = Mixpanel::Tracker.new(MIXPANEL_TOKEN)
    tracker.track(log.session_id, log.action, log.attributes)
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end

  def data_dog(log)
    statsd = Statsd.new('localhost', 8125)
    statsd.increment('egotter.search.total')
    statsd.increment("egotter.search.#{log.action}")
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end
end
