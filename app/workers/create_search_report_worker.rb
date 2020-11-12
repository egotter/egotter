class CreateSearchReportWorker
  include Sidekiq::Worker
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

    if PeriodicReport.send_report_limited?(searchee.uid)
      logger.warn "Send search report later searchee_id=#{searchee_id} raised=false"
      CreateSearchReportWorker.perform_in(1.hour + rand(30).minutes, searchee_id, options.merge(delay: true))
      return
    end

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      logger.warn "Send search report later searchee_id=#{searchee_id} raised=true"
      CreateSearchReportWorker.perform_in(1.hour + rand(30).minutes, searchee_id, options.merge(delay: true))
    elsif TwitterApiStatus.unauthorized?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_allowed_to_access_or_delete?(e) ||
        DirectMessageStatus.cannot_send_messages?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} searchee_id=#{searchee_id} options=#{options.inspect}"
    end
  end
end
