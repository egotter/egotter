class CreateSignedInTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false
end
