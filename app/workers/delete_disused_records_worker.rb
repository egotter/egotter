class DeleteDisusedRecordsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(uid, options = {})
    CloseFriendship.delete_by_uid(uid)
    FavoriteFriendship.delete_by_uid(uid)
    OneSidedFriendship.delete_by_uid(uid)
    OneSidedFollowership.delete_by_uid(uid)
    MutualFriendship.delete_by_uid(uid)
    InactiveFriendship.delete_by_uid(uid)
    InactiveFollowership.delete_by_uid(uid)
    InactiveMutualFriendship.delete_by_uid(uid)
    Unfriendship.delete_by_uid(uid)
    Unfollowership.delete_by_uid(uid)
    BlockFriendship.delete_by_uid(uid)
  rescue => e
    Airbag.exception e, uid: uid, options: options
  end
end
