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
      CreateSearchReportWorker.perform_in(1.hour, searchee_id, options.merge(delay: true))
      return
    end

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!
  rescue => e
    if TwitterApiStatus.unauthorized?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_allowed_to_access_or_delete?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} searchee_id=#{searchee_id} options=#{options.inspect}"
    end
  end
end
