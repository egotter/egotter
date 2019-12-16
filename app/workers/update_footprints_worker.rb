class UpdateFootprintsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  #def unique_key(search_log_id, options = {})
  #  options['user_id']
  #end

  def unique_in
    1.minute
  end

  # options:
  #   user_id
  def perform(search_log_id, options = {})
    log = SearchLog.find(search_log_id)

    if log.with_login?
      user = log.user

      assign_user_access_at(user, log)
      user.save! if user.changed?

      assign_user_search_at(user, log)
      user.save! if user.changed?
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{search_log_id}"
    logger.info e.backtrace.join("\n")
  end

  private

  def assign_user_access_at(user, log)
    if user[:first_access_at].nil? || log.created_at < user[:first_access_at]
      user[:first_access_at] = log.created_at
    end

    if user[:last_access_at].nil? || user[:last_access_at] < log.created_at
      user[:last_access_at] = log.created_at
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{log.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def assign_user_search_at(user, log)
    return unless log.controller == 'timelines' && log.action == 'show' && user.uid == log.uid

    if user[:first_search_at].nil? || log.created_at < user[:first_search_at]
      user[:first_search_at] = log.created_at
    end

    if user[:last_search_at].nil? || user[:last_search_at] < log.created_at
      user[:last_search_at] = log.created_at
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{log.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
