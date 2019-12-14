class CreateAccessDayWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.hour
  end

  def perform(user_id, options = {})
    user = User.find(user_id)
    date = Time.zone.now.in_time_zone('Tokyo').to_date

    unless user.access_days.exists?(date: date)
      user.access_days.create!(date: date)
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
  end
end
