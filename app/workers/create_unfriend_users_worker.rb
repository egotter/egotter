class CreateUnfriendUsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(user_id, from_uid, uids, options = {})
    from_uid
  end

  def unique_in
    3.minutes
  end

  # options:
  def perform(user_id, from_uid, uids, options = {})
    return if uids.empty?

    users = TwitterDB::User.order_by_field(uids).where(uid: uids).index_by(&:uid)
    missing_uids = uids.select { |uid| users[uid].nil? }

    if missing_uids.any?
      Airbag.info "Stop creating records as missing uids are found missing_uids=#{missing_uids}"
      CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: user_id, enqueued_by: self.class)
    else
      UnfriendUser.import_data(from_uid, users.values)
    end
  rescue => e
    Airbag.warn "#{e.inspect.truncate(200)} user_id=#{user_id} from_uid=#{from_uid} options=#{options}"
    Airbag.info e.backtrace.join("\n")
  end
end
