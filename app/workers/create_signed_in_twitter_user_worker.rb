# TODO Remove later
class CreateSignedInTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def after_skip(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    request.status_message = [request.status_message, 'Skipped'].reject { |str| str.blank? }.join(',')
    request.save
    SkippedCreateSignedInTwitterUserWorker.perform_async(request_id, options)
  end

  def after_expire(request_id, options = {})
    ExpiredCreateSignedInTwitterUserWorker.perform_async(request_id, options)
  end
end
