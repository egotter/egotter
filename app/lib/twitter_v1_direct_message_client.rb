class TwitterV1DirectMessageClient
  def initialize(uid: nil, screen_name: nil)
    if uid
      user = User.find_by(uid: uid)
    else
      user = User.find_by(screen_name: screen_name)
    end

    @client = user.api_client.twitter # TwitterClient
  end

  def direct_message(id)
    event = @client.direct_message_event(id)
    DirectMessageWrapper.from_event(event.to_h)
  end

  def direct_messages(*args)
    events = @client.direct_messages_events(*args)
    events.map { |e| DirectMessageWrapper.from_event(e.to_h) }
  end
end

