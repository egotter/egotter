class CreateDeleteTweetsByArchiveStopRequestedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = '停止しました。アーカイブデータを使った削除を再開したい場合は、アーカイブデータのアップロードからやり直してください。#egotter'

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    event = DirectMessageEvent.build(uid, MESSAGE)
    User.egotter_cs.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
