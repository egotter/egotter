module WorkerIdsFetcher
  def unique_key(uid, cursor, options = {})
    "#{uid}:#{cursor}"
  end

  def unique_in
    10.minutes
  end

  def expire_in
    10.minutes
  end

  def fetch_friend_ids(uid, cursor)
    fetch_ids(:friend_ids, uid, cursor)
  end

  def fetch_follower_ids(uid, cursor)
    fetch_ids(:follower_ids, uid, cursor)
  end

  def fetch_ids(api_name, uid, cursor)
    client = Bot.api_client.twitter
    response = client.send(api_name, uid, count: 5000, cursor: cursor)&.attrs
    if response.nil?
      {}
    else
      {ids: response[:ids], next_cursor: response[:next_cursor]}
    end
  end
end
