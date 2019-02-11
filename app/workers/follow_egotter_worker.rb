class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    request =
        FollowRequest.order(created_at: :desc).
            where(uid: User::EGOTTER_UID).
            where(finished_at: nil).
            without_error.first

    request&.perform

    self.class.perform_in(FollowRequest.current_interval)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    self.class.perform_in(FollowRequest.long_limit_interval)
  end
end
