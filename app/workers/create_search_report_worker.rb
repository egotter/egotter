class CreateSearchReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
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
    return if !searchee.authorized? || !searchee.notification_setting.can_send_search?

    SearchReport.you_are_searched(searchee.id, options['searcher_uid']).deliver!

  rescue => e
    if AccountStatus.unauthorized?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.you_have_blocked?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} searchee_id=#{searchee_id} options=#{options.inspect}"
      notify_airbrake(e, searchee_id: searchee_id, options: options)
    end
  end
end
