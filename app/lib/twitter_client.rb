class TwitterClient
  attr_reader :api_name

  def initialize(api_client, twitter)
    @api_client = api_client
    @twitter = twitter
    @api_name = nil
  end

  [:user_agent, :user_token?, :credentials, :proxy, :timeouts].each do |method_name|
    define_method(method_name) do |*args, &blk|
      @twitter.send(method_name, *args, &blk)
    end
  end

  def verify_credentials(*args, **kwargs)
    call_api(__method__, *args, **kwargs)
  ensure
    CreateTwitterApiLogWorker.perform_async(name: __method__)
  end

  def users(*args, **kwargs)
    call_api(__method__, *args, **kwargs)
  ensure
    CreateTwitterApiLogWorker.perform_async(name: __method__)
  end

  def follow!(*args, **kwargs)
    call_api(__method__, *args, **kwargs)
  ensure
    CreateTwitterApiLogWorker.perform_async(name: __method__)
  end

  def unfollow(*args, **kwargs)
    call_api(__method__, *args, **kwargs)
  ensure
    CreateTwitterApiLogWorker.perform_async(name: __method__)
  end

  def user_timeline(*args, **kwargs)
    call_api(__method__, *args, **kwargs)
  ensure
    CreateTwitterApiLogWorker.perform_async(name: __method__)
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

  # TODO List api methods
  def method_missing(method, *args, **kwargs, &block)
    if @twitter.respond_to?(method)
      Airbag.info { "ApiClient::TwitterClient#method_missing: #{method} is not implemented" }
      call_api(method, *args, **kwargs, &block)
    else
      super
    end
  end

  def call_api(method, *args, **kwargs, &block)
    @api_name = method

    ApiClient::RequestWithRetryHandler.new(method).perform do
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
  end
end