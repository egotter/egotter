class CreateSearchReportWorker
  include Sidekiq::Worker
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

  rescue Twitter::Error::Forbidden => e
    if e.message == 'You cannot send messages to users you have blocked.' ||
        e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
      logger.info "#{e.class}: #{e.message} #{searchee_id} #{options.inspect}"
    else
      logger.warn "#{e.class}: #{e.message} #{searchee_id} #{options.inspect}"
    end
    logger.info e.backtrace.join("\n")
  rescue => e
    if AccountStatus.unauthorized?(e)
    else
      logger.warn "#{e.class}: #{e.message} #{searchee_id} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end
