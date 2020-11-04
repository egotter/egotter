class CreateBlockReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    1.hour
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless send_report?(user)

    if BlockingRelationship.where(to_uid: user.uid).exists?
      BlockReport.you_are_blocked(user.id).deliver!
    end
  rescue => e
    if TwitterApiStatus.unauthorized?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_allowed_to_access_or_delete?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end

  private

  def send_report?(user)
    user.authorized? && !StopBlockReportRequest.exists?(user_id: user.id)
  end
end
