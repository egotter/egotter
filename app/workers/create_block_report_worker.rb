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
    return unless user.authorized?

    blocked_uids = BlockingRelationship.where(to_uid: user.uid).order(created_at: :desc).limit(10).pluck(:from_uid).uniq
    users = user.api_client.users(blocked_uids).map { |user| {uid: user[:id], screen_name: user[:screen_name]} }
    BlockReport.you_are_blocked(user.id, users).deliver! if users.any?
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
end
