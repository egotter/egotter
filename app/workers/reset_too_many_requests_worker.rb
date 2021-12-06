class ResetTooManyRequestsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id)
    TooManyRequestsUsers.new.delete(user_id)
  rescue => e
    Airbag.warn "#{e.class} #{e.message} #{user_id}"
  end
end
