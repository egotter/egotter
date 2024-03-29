class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  prepend WorkMeasurement
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.minutes
  end

  def timeout_in
    3.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: UpdateEgotterFollowersWorker is stopped'
      return
    end

    EgotterFollower.update_all_uids
  rescue => e
    handle_worker_error(e, **options)
  end
end
