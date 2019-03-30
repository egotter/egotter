class UpdateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(search_log_id)
    log = SearchLog.find(search_log_id)
    log.save! if log.changed?

    if log.with_login?
      update_user_access_at(log)
      update_user_search_at(log)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{search_log_id}"
  end

  private

  def update_user_access_at(log)
    user = log.user

    if user[:first_access_at].nil? || log.created_at < user[:first_access_at]
      user[:first_access_at] = log.created_at
    end

    if user[:last_access_at].nil? || user[:last_access_at] < log.created_at
      user[:last_access_at] = log.created_at
    end

    user.save! if user.changed?

  rescue => e
    logger.warn "#{e.class} #{e.message} #{log.inspect}"
  end

  def update_user_search_at(log)
    user = log.user
    return unless log.controller == 'timelines' && log.action == 'show' && user.uid == log.uid


    if user[:first_search_at].nil? || log.created_at < user[:first_search_at]
      user[:first_search_at] = log.created_at
    end

    if user[:last_search_at].nil? || user[:last_search_at] < log.created_at
      user[:last_search_at] = log.created_at
    end

    user.save! if user.changed?

  rescue => e
    logger.warn "#{e.class} #{e.message} #{log.inspect}"
  end
end
