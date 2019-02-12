class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    10.times do
      request = do_perform
      break if !request || !request.finished?
    end

    self.class.perform_in(FollowRequest.current_interval)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    self.class.perform_in(FollowRequest.long_limit_interval)
  end

  def do_perform
    request =
        FollowRequest.order(created_at: :desc).
            where(uid: User::EGOTTER_UID).
            where(finished_at: nil).
            without_error.first

    return unless request

    request.perform
    logger.info {"#{self.class}##{__method__} #{request.inspect}"}

    request
  end
end
