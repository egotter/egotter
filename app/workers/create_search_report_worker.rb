class CreateSearchReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(searchee_id, options = {})
    searchee_id
  end

  # options:
  #   searcher_uid
  def perform(searchee_id, options = {})
    searchee = User.find(searchee_id)
    return if !searchee.authorized? || !searchee.notification_setting.can_send_search?

    # TODO Implement email
    # TODO Implement onesignal

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!

  rescue => e
    if AccountStatus.unauthorized?(e)
    else
      notify_airbrake(e, searchee_id: searchee_id, options: options)
    end
  end
end
