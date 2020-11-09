class DeleteDisusedRecordsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(uid, options = {})
    # TODO Remove later
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
    logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
