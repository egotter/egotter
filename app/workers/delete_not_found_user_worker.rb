class DeleteNotFoundUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(screen_name)
    queue = RunningQueue.new(self.class)
    return if queue.exists?(screen_name)
    queue.add(screen_name)

    NotFoundUser.find_by(screen_name: screen_name)&.delete
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{screen_name}"
  end
end
