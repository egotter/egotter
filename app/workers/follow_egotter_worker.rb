class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    request =
        FollowRequest.order(created_at: :desc).
            where(uid: User::EGOTTER_UID).
            where(finished_at: nil).
            without_error.first

    request&.enqueue(enqueue_location: 'FollowEgotterWorker')

    self.class.perform_in(FollowRequest.current_interval)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    self.class.perform_in(30.minutes)
  end
end
