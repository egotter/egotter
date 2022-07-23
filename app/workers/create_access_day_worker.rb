class CreateAccessDayWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    "#{user_id}-#{AccessDay.current_date}"
  end

  def unique_in
    1.hour
  end

  def perform(user_id, options = {})
    user = User.find(user_id)
    create_record(user)
  rescue ActiveRecord::RecordNotUnique => e
    Airbag.info e.message.truncate(100)
  rescue => e
    Airbag.exception e, user_id: user_id, options: options
  end

  def create_record(user)
    time = Time.zone.now
    date = AccessDay.current_date

    unless user.access_days.exists?(date: date)
      user.access_days.create(date: date, time: time)
    end

    true
  rescue => e
    false
  end
end
