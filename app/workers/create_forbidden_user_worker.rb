class CreateForbiddenUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    options['uid'] ? options['uid'] : screen_name
  end

  def unique_in
    1.minute
  end

  # options:
  #   uid
  def perform(screen_name, options = {})
    ForbiddenUser.create!(screen_name: screen_name)
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{screen_name}"
    logger.info e.backtrace.join("\n")
  end
end
