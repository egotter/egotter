class DeleteInactiveFriendshipsWorker
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
    InactiveFriendship.delete_by_uid(uid)
    InactiveFollowership.delete_by_uid(uid)
    InactiveMutualFriendship.delete_by_uid(uid)
  rescue => e
    Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
  end
end
