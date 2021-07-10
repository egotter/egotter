class CreateDeleteTweetsInvalidRequestMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    template = Rails.root.join('app/views/delete_tweets/invalid_request.ja.text.erb')
    message = ERB.new(template.read).result_with_hash(
        delete_tweets_url: Rails.application.routes.url_helpers.delete_tweets_url(og_tag: 'false'),
        request_token: find_request_token(uid),
        expiry: DateHelper.distance_of_time_in_words(DeleteTweetsRequest::REQUEST_TOKEN_EXPIRY)
    )
    event = DeleteTweetsReport.build_direct_message_event(uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  def find_request_token(uid)
    if (user = User.find_by(uid: uid)) &&
        (request = DeleteTweetsRequest.find_token(user.id))
      request.request_token
    else
      'xxxxxx'
    end
  end

  module DateHelper
    extend ActionView::Helpers::DateHelper
  end
end
