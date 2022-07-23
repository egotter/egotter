require 'digest/md5'

class ImportTwitterDBSuspendedUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uids, options = {})
    Digest::MD5.hexdigest(uids.to_json)
  end

  def unique_in
    10.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(uids, options = {})
    if (uids -= TwitterDB::User.where(uid: uids).pluck(:uid)).any?
      users = uids.map { |uid| {id: uid, screen_name: 'suspended', description: ''} }
      ImportTwitterDBUserWorker.perform_async(users)
    end
  rescue => e
    Airbag.exception e, uids: uids
  end
end
