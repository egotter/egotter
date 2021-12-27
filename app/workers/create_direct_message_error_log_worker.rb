# TODO Remove later
class CreateDirectMessageErrorLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(event_args, error_class, error_message, time, options = {})
    attrs = {
        sender_id: options['sender_id'],
        recipient_id: dig_recipient_id(event_args),
        error_class: error_class,
        error_message: error_message,
        properties: event_args,
        created_at: time,
    }
    DirectMessageErrorLog.create!(attrs)
  rescue => e
    Airbag.warn "#{e.inspect} event_args=#{event_args.inspect} error_class=#{error_class} error_message=#{error_message} time=#{time}"
  end

  private

  def dig_recipient_id(args)
    if args.length == 1 && args.last.is_a?(Hash)
      args.last.dig('event', 'message_create', 'target', 'recipient_id')
    elsif args.length == 2 && args.first.is_a?(Integer)
      args.first
    else
      nil
    end
  rescue => e
    nil
  end
end
