class CreateSearchReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
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
    return unless searchee.authorized?
    return if StopSearchReportRequest.exists?(user_id: searchee.id)
    return if (searcher = User.find_by(uid: options['searcher_uid'])) && SneakSearchRequest.exists?(user_id: searcher.id)

    if PeriodicReport.send_report_limited?(searchee.uid)
      retry_current_job(searchee_id, options)
      return
    end

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_job(searchee_id, options, exception: e)
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} searchee_id=#{searchee_id} options=#{options.inspect}"
    end
  end

  def retry_current_job(user_id, options, exception: nil)
    logger.add(exception ? Logger::WARN : Logger::INFO) { "#{self.class} will be performed again user_id=#{user_id} exception=#{exception.inspect}" }
    CreateSearchReportWorker.perform_in(1.hour + rand(30).minutes, user_id, options)
  end
end
