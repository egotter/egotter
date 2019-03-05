class UpdateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(search_log_id)
    log = SearchLog.find(search_log_id)
    log.assign_attributes(landing: landing_page?(log), first_time: first_time_session?(log))
    log.save! if log.changed?

    reassign_channel(log)

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

  def landing_page?(log)
    !log.referer.start_with?('https://egotter.com') &&
        !SearchLog.exists?(session_id: log.session_id, created_at: (log.created_at - 30.minutes)..log.created_at)
  end

  def first_time_session?(log)
    !SearchLog.exists?(session_id: log.session_id)
  end

  def reassign_channel(log)
    channel =
      if log.landing?
        case
          when log.channel.blank? then 'direct'
          when log.channel == 'twitter' && log.medium == 'dm' then 'dm'
          else log.channel
        end
      else
        log.channel
      end

    if channel.blank? || channel == 'others'
      logs =
        SearchLog
          .where(session_id: log.session_id, created_at: (log.created_at - 30.minutes)..log.created_at)
          .where.not(channel: ['', 'others'])
          .order(created_at: :desc)
          .limit(1)
          .to_a

      channel = logs[0].channel if logs.any?
    end

    log.assign_attributes(channel: channel)
    log.save! if log.changed?

  rescue => e
    logger.warn "##{__method__} #{e.class} #{e.message} #{log.inspect}"
  end
end
