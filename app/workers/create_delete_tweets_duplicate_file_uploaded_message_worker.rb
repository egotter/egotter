class CreateDeleteTweetsDuplicateFileUploadedMessageWorker
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
  def perform(user_id, options = {})
    user = User.find(user_id)
    user.api_client.verify_credentials

    unless User.egotter_cs.api_client.can_send_dm?(user.uid)
      DeleteTweetsReport.send_duplicate_file_uploaded_starting_message(user)
    end

    DeleteTweetsReport.duplicate_file_uploaded_message(user).deliver!
  rescue => e
    Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}", backtrace: e.backtrace
  end
end
