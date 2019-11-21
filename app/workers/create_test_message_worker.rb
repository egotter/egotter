class CreateTestMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def timeout_in
    1.minute
  end

  # options:
  #   error_class
  #   error_message
  #   enqueued_at
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    if options['error_class']
      TestMessage.need_fix(user.id, options['error_class'], options['error_message']).deliver!
    else
      TestMessage.ok(user.id).deliver!
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
