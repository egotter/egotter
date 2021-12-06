class CreateCloseFriendsQuestionedMessageWorker
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

    template = Rails.root.join('app/views/close_friends/questioned.ja.text.erb')
    message = ERB.new(template.read).result_with_hash({})
    event = CloseFriendsReport.build_direct_message_event(uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
