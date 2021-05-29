class ImportEmptyTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(klass, uid, screen_name, options = {})
    "#{klass}-#{uid}"
  end

  def unique_in
    3.minutes
  end

  # options:
  def perform(klass, uid, screen_name, options = {})
    klass.constantize.import_from!(uid, screen_name, [])
  rescue => e
    handle_worker_error(e, klass: klass, uid: uid, screen_name: screen_name, options: options)
  end
end
