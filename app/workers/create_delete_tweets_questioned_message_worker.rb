class CreateDeleteTweetsQuestionedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(uid, options = {})

    template = Rails.root.join('app/views/delete_tweets/questioned.ja.text.erb')
    message = ERB.new(template.read).result_with_hash({})
    event = DeleteTweetsReport.build_direct_message_event(uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    if TwitterApiStatus.unauthorized?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_allowed_to_access_or_delete?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
