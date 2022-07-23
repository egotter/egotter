class CreateSearchReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include ReportRetryHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(searchee_id, options = {})
    searchee_id
  end

  def unique_in(*args)
    1.hour
  end

  # options:
  #   searcher_uid
  def perform(searchee_id, options = {})
    searchee = User.find(searchee_id)
    return if searchee.unauthorized_or_expire_token?
    return if StopSearchReportRequest.exists?(user_id: searchee.id)
    return if searchee.banned?
    return if (searcher = User.find_by(uid: options['searcher_uid'])) && SneakSearchRequest.exists?(user_id: searcher.id)

    if PeriodicReport.send_report_limited?(searchee.uid)
      retry_current_report(searchee_id, options)
      return
    end

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_report(searchee_id, options)
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      Airbag.exception e, searchee_id: searchee_id, options: options
    end
  end
end
