class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(*args)
    10.times do
      request = do_perform
      break if !request || !request.finished?
    end

    self.class.perform_in(FollowRequest.current_interval)
  rescue Twitter::Error::Forbidden => e
    if e.message == 'Your account is suspended and is not permitted to access this feature.'
      logger.info "#{e.class} #{e.message}"
    else
      logger.warn "#{e.class} #{e.message}"
    end

    self.class.perform_in(retry_in)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    self.class.perform_in(retry_in)
  end

  def retry_in
    60.minutes
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
