class CreateDeleteTweetsRequestStartedMessageWorker
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
    template = Rails.root.join('app/views/delete_tweets/request_started.ja.text.erb')
    message = ERB.new(template.read).result_with_hash(
        delete_tweets_url: Rails.application.routes.url_helpers.delete_tweets_url(og_tag: 'false')
    )
    event = DeleteTweetsReport.build_direct_message_event(uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
