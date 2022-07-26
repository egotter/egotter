class CreateDirectMessageReceiveLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    attrs.stringify_keys! # This worker could be run synchronously
    attrs['automated'] = !!attrs['message']&.include?('#egotter')
    DirectMessageReceiveLog.create!(attrs)
  rescue ActiveRecord::StatementInvalid => e
    Airbag.warn e.inspect, attrs: attrs, options: options
  rescue => e
    Airbag.exception e, attrs: attrs, options: options
  end
end
