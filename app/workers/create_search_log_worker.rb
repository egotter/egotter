class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(attrs)
    attrs.delete('via') unless SearchLog.new.respond_to?(:via)
    attrs.delete('bouncing') unless SearchLog.new.respond_to?(:bouincing)
    attrs.delete('exiting') unless SearchLog.new.respond_to?(:exiting)

    log = SearchLog.new(attrs)
    log.assign_attributes(landing: landing_page?(log), first_time: first_time_session?(log))
    log.save!

    reassign_channel(log) unless log.crawler?
    assign_timestamps(log) if log.with_login?
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{attrs.inspect}"
  end

  private

  def assign_timestamps(log)
    user = User.find(log.user_id)
    assign_timestamp(user, :first_access_at, log.created_at, :>)
    assign_timestamp(user, :last_access_at, log.created_at, :<)

    if log.action == 'show' && user.uid.to_i == log.uid.to_i
      assign_timestamp(user, :first_search_at, log.created_at, :>)
      assign_timestamp(user, :last_search_at, log.created_at, :<)
    end

    user.save! if user.changed?

  rescue => e
    logger.warn "#{e.class}: #{e.message} #{log.inspect}"
  end

  def assign_timestamp(user, attr, value, less_or_greater)
    if user[attr].nil? || user[attr].send(less_or_greater, value)
      user[attr] = value
    end
  end

  def landing_page?(log)
    !log.crawler? && !log.referer.start_with?('https://egotter.com') &&
      !SearchLog.exists?(session_id: log.session_id, created_at: 30.minutes.ago..log.created_at)
  end

  def first_time_session?(log)
    !log.crawler? && !SearchLog.exists?(session_id: log.session_id)
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
          .where(session_id: log.session_id, created_at: 30.minutes.ago..log.created_at)
          .where.not(channel: ['', 'others'])
          .order(created_at: :desc)
          .limit(1)
          .to_a

      channel = logs[0].channel if logs.any?
    end

    log.assign_attributes(channel: channel)
    log.save! if log.changed?

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{log.inspect}"
  end
end
