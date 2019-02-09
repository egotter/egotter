class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    request =
        FollowRequest.order(created_at: :desc).
            where(uid: User::EGOTTER_UID).
            where(finished_at: nil).
            without_error.first

    if request
      WorkersHelper.enqueue_create_follow_job_if_needed(request.user_id, enqueue_location: 'FollowEgotterWorker')
    end

    interval = Concerns::User::FollowAndUnfollow::Util.global_can_create_follow? ? 30.seconds : 30.minutes
    self.class.perform_in(interval)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    self.class.perform_in(30.minutes)
  end
end
