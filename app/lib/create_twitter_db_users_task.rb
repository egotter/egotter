class CreateTwitterDBUsersTask
  def initialize(uids, user_id: nil, enqueued_by: nil)
    @uids = uids.uniq.map(&:to_i)
    @user_id = user_id
    @enqueued_by = enqueued_by
  end

  def start
    uids = @uids - TwitterDB::QueuedUser.where(uid: @uids).pluck(:uid)
    return if uids.empty?

    begin
      TwitterDB::QueuedUser.import_data(uids)
    rescue => e
      Airbag.warn "CreateTwitterDBUsersTask#start: #{e.inspect.truncate(200)}"
    end

    users = client.safe_users(uids).map(&:to_h)

    if uids.size != users.size && (suspended_uids = uids - users.map { |u| u[:id] }).any?
      Airbag.info 'Import suspended uids', uids: uids, suspended_uids: suspended_uids
      ImportTwitterDBSuspendedUserWorker.perform_async(suspended_uids)
    end

    if users.any?
      # ImportTwitterDBUserWorker.perform_async(users, enqueued_by: @enqueued_by, _user_id: @user_id, _size: users.size)
      ImportTwitterDBUserWorker.perform_in(rand(10) + 3, users, enqueued_by: @enqueued_by, _user_id: @user_id, _size: users.size)
    end
  end

  private

  def client
    if @user_id && !RateLimitExceededFlag.on?(@user_id)
      User.find(@user_id).api_client.twitter
    else
      Bot.api_client.twitter
    end
  end
end
