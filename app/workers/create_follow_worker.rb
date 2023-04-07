class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  def retry_in
    1.hour + rand(30.minutes)
  end

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateFollowWorker is stopped', request_id: request_id
      return
    end

    if GlobalFollowLimitation.new.limited?
      CreateFollowWorker.perform_in(retry_in, request_id, options)
    else
      request = FollowRequest.find(request_id)
      CreateFollowTask.new(request).start!
    end

  rescue FollowRequest::AlreadyFollowing,
      FollowRequest::AlreadyRequestedToFollow,
      FollowRequest::NotFound,
      FollowRequest::Suspended,
      FollowRequest::Blocked,
      FollowRequest::Unauthorized,
      FollowRequest::CanNotFollowYourself,
      FollowRequest::TemporarilyLocked => e
    Airbag.info "Skip #{e.inspect}"
  rescue FollowRequest::TooManyFollows, FollowRequest::ServiceUnavailable => e
    retry_interval = retry_in
    Airbag.warn "Retry later exception=#{e.inspect}#{" cause=#{e.cause.inspect}" if e.cause} request_id=#{request_id} retry_interval=#{retry_interval} process_rate=#{calc_process_rate}"
    CreateFollowWorker.perform_in(retry_interval, request_id, options)

  rescue FollowRequest::RetryableError => e
    CreateFollowWorker.perform_async(request_id, options)

  rescue FollowRequest::Error => e
    Airbag.warn "Don't care. #{e.inspect} request_id=#{request_id} options=#{options}"

  rescue => e
    Airbag.warn "Don't retry. #{e.inspect} request_id=#{request_id} options=#{options} #{"Caused by #{e.cause.inspect}" if e.cause}", backtrace: e.backtrace
  end

  # Requests / 24-hour window: 400 per user; 1000 per app
  # 0.69/1min, 20.8/30min, 41/hour, 125/3hours, 500/12hours
  def calc_process_rate
    [1.minute, 30.minutes, 1.hour, 3.hours, 12.hours, 24.hours].map do |time|
      [time, FollowRequest.where('created_at > ?', time.ago).size]
    end.map { |time, count| "#{time.inspect.remove(' ')}=#{count}" }.join(' ')
  rescue => e
    nil
  end
end
