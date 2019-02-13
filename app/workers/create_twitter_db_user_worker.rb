class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uids)
    TwitterDB::User::Batch.fetch_and_import(uids.map(&:to_i), client: Bot.api_client)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(150)}"
    logger.info e.backtrace.join("\n")
  end
end
