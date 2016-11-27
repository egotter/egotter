class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(attrs)
    log = SearchLog.new(attrs)
    log.assign_attributes(landing: landing_page?(log), first_time: first_time_session?(log))
    log.save!

    if log.user_id != -1
      user = User.find(log.user_id)
      assign_timestamp(user, :first_access_at, log.created_at, :>)
      assign_timestamp(user, :last_access_at, log.created_at, :<)

      if log.action == 'show' && user.uid.to_i == log.uid.to_i
        assign_timestamp(user, :first_search_at, log.created_at, :>)
        assign_timestamp(user, :last_search_at, log.created_at, :<)
      end

      user.save! if user.changed?
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end

  private

  def assign_timestamp(user, attr, value, less_or_greater)
    if user[attr].nil? || user[attr].send(less_or_greater, value)
      user[attr] = value
    end
  end

  def landing_page?(log)
    log.device_type != 'crawler' && log.session_id != '-1' && !log.referer.start_with?('https://egotter.com') &&
      !SearchLog.exists?(session_id: log.session_id, created_at: 30.minutes.ago..log.created_at)
  end

  def first_time_session?(log)
    log.device_type != 'crawler' && log.session_id != '-1' &&
      !SearchLog.exists?(session_id: log.session_id)
  end
end
