# TODO Remove later
class DeleteNotFoundUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'DeleteNotFoundUserWorker', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    screen_name
  end

  def unique_in
    1.minute
  end

  def perform(screen_name, options = {})
    NotFoundUser.find_by(screen_name: screen_name)&.delete
  rescue ActiveRecord::RecordNotUnique => e
    # Do nothing
  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
  end
end
