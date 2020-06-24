class CreateNotFoundUserWorker
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
    NotFoundUser.create!(screen_name: screen_name)
    DeleteNotFoundUserWorker.perform_in(15.minutes, screen_name)
  rescue ActiveRecord::RecordNotUnique => e
    # Do nothing
  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name}"
  end
end
