class CreateGreetingGoodAfternoonMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   text
  def perform(uid, options = {})
    User.egotter.api_client.create_direct_message(uid, I18n.t('workers.chat_messages.good_afternoon').sample)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
