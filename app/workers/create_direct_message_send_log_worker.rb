class CreateDirectMessageSendLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    attrs['automated'] = attrs['message']&.include?('#egotter')
    DirectMessageSendLog.create!(attrs)
  rescue ActiveRecord::StatementInvalid => e
    Airbag.warn e.inspect, attrs: attrs, options: options
  rescue => e
    Airbag.exception e, attrs: attrs, options: options
  end
end
