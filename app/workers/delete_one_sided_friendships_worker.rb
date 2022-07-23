class DeleteOneSidedFriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    10.seconds
  end

  # options:
  def perform(uid, options = {})
    OneSidedFriendship.delete_by_uid(uid)
    OneSidedFollowership.delete_by_uid(uid)
    MutualFriendship.delete_by_uid(uid)
  rescue => e
    Airbag.exception e, uid: uid, options: options
  end
end
