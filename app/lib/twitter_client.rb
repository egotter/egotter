class TwitterClient
  attr_reader :api_name

  def initialize(api_client, twitter)
    @api_client = api_client
    @twitter = twitter
    @api_name = nil
  end

  [:user_agent, :user_token?, :credentials, :proxy, :timeouts,
   :friend_ids, :follower_ids, :friendship?, :destroy_status, :unfavorite!,
   :user, :users, :user?, :status, :friendships_outgoing, :muted_ids, :blocked_ids,
   :favorites, :update, :update!, :verify_credentials, :follow!, :unfollow, :user_timeline].each do |method|
    define_method(method) do |*args, **kwargs, &blk|
      call_api(method, *args, **kwargs, &blk)
    end
  end

  def create_direct_message_event(*args, **kwargs)
    dm = DirectMessageWrapper.from_args(args, kwargs)

    if !DirectMessageReceiveLog.message_received?(dm.recipient_id) && DirectMessageLimitedFlag.on?
      error_message = "Sending DM is rate-limited remaining=#{DirectMessageLimitedFlag.remaining} recipient_id=#{dm.recipient_id} text=#{dm.text.truncate(100)}"
      raise ApiClient::EnhanceYourCalm.new(error_message)
    end

    begin
      call_api(__method__, *args, **kwargs)
    rescue Twitter::Error::EnhanceYourCalm => e
      DirectMessageLimitedFlag.on
      raise ApiClient::EnhanceYourCalm.new("recipient_id=#{dm.recipient_id} text=#{dm.text.truncate(100)}")
    end
  end

  # TODO Implement all methods and stop using #method_missing
  def method_missing(method, *args, **kwargs, &block)
    if @twitter.respond_to?(method)
      Airbag.info { "TwitterClient#method_missing: #{method} is not implemented" }
      call_api(method, *args, **kwargs, &block)
    else
      super
    end
  end

  def call_api(method, *args, **kwargs, &block)
    @api_name = method

    TwitterRequest.new(method).perform do
      # TODO This conditional branch may not be needed on Ruby30
      if kwargs.empty?
        @twitter.send(method, *args, &block)
      else
        @twitter.send(method, *args, **kwargs, &block)
      end
    end
  rescue => e
    @api_client.update_authorization_status(e)
    @api_client.update_lock_status(e)
    raise
  ensure
    CreateTwitterApiLogWorker.perform_async(name: "TwitterClient##{method}")
  end
end