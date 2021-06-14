class CreateDeleteFavoritesUploadCompletedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   :since
  #   :until
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    DeleteFavoritesReport.send_upload_completed_starting_message(user)
    DeleteFavoritesReport.upload_completed_message(user, options).deliver!
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end
