class DeleteNotFoundUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  def unique_key(screen_name)
    screen_name
  end

  def unique_in
    1.minute
  end

  def perform(screen_name)
    NotFoundUser.find_by(screen_name: screen_name)&.delete
  rescue ActiveRecord::RecordNotUnique => e
    # Do nothing
  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name}"
  end
end
