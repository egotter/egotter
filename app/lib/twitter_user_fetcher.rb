class TwitterUserFetcher
  attr_reader :api_name

  def initialize(client, uid, screen_name, fetch_friends, search_for_yourself, reporting)
    @api_client = client # with :null_store
    @uid = uid
    @search_query = "@#{screen_name}"
    @fetch_friends = fetch_friends
    @search_for_yourself = search_for_yourself
    @reporting = reporting
  end

  def fetch
    fetch_in_threads
  rescue ThreadError => e
    Airbag.warn "TwitterUserFetcher#fetch: ThreadError is detected and retry without threads exception=#{e.inspect} thread=#{Thread.current.inspect}", backtrace: e.backtrace
    fetch_without_threads
  end

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch_without_threads
    result = {}
    client = ClientWrapper.new(@api_client, @api_client.twitter)

    if @fetch_friends
      result[:friend_ids] = client.friend_ids(@uid)
      result[:follower_ids] = client.follower_ids(@uid)
    end

    if @search_for_yourself
      result[:mentions_timeline] = client.mentions_timeline
    else
      result[:search] = client.search(@search_query)
    end

    unless @reporting
      result[:user_timeline] = client.user_timeline(@uid)
    end

    result[:favorites] = client.favorites(@uid)

    result
  end

  def fetch_in_threads
    threads = []
    client = ClientWrapper.new(@api_client, @api_client.twitter)

    if @fetch_friends
      threads << Thread.new(client.copy, @uid) { |c, u| [:friend_ids, c.friend_ids(u)] }
      threads << Thread.new(client.copy, @uid) { |c, u| [:follower_ids, c.follower_ids(u)] }
    end

    if @search_for_yourself
      threads << Thread.new(client) { |c| [:mentions_timeline, c.mentions_timeline] }
    else
      threads << Thread.new(client, @search_query) { |c, q| [:search, c.search(q)] }
    end

    unless @reporting
      threads << Thread.new(client, @uid) { |c, u| [:user_timeline, c.user_timeline(u)] }
    end

    threads << Thread.new(client, @uid) { |c, u| [:favorites, c.favorites(u)] }

    threads.each(&:join)
    threads.map(&:value).to_h
  end

  private

  class ClientWrapper
    def initialize(client, twitter_client)
      @client = client
      @twitter_client = twitter_client
    end

    def friend_ids(uid)
      collect_with_max_id(uid) do |options|
        @twitter_client.friend_ids(uid, options)
      end
    end

    def follower_ids(uid)
      collect_with_max_id(uid) do |options|
        @twitter_client.follower_ids(uid, options)
      end
    end

    def user_timeline(uid)
      @client.user_timeline(uid, include_rts: false)
    rescue => e
      handle_exception(e)
    end

    def mentions_timeline
      @client.mentions_timeline
    rescue => e
      handle_exception(e)
    end

    def search(word)
      @client.search(word)
    rescue => e
      handle_exception(e)
    end

    def favorites(uid)
      @client.favorites(uid)
    rescue => e
      handle_exception(e)
    end

    def copy
      self.class.new(@client, @twitter_client)
    end

    private

    def collect_with_max_id(uid, &block)
      options = {count: 5000, cursor: -1}
      collection = []
      calls_count = 0

      50.times do
        begin
          if @twitter_client.app_context? && (calls_count += 1) > 3
            raise Twitter::Error::TooManyRequests.new('periodic reload')
          end
          response = yield(options)
        rescue => e
          if client_reloadable?(e, uid)
            @twitter_client = Bot.api_client.twitter
            calls_count = 0
            Airbag.info "TwitterUserFetcher::ClientWrapper: Reloaded uid=#{uid} message=#{e.message}"
            retry
          else
            raise
          end
        end
        break if response.nil?

        attrs = response.attrs
        collection.concat(attrs[:ids])

        break if attrs[:next_cursor] == 0

        options[:cursor] = attrs[:next_cursor]
      end

      collection
    end

    def client_reloadable?(e, uid)
      TwitterApiStatus.too_many_requests?(e) &&
          (@twitter_client.app_context? || !(@client.user(uid)[:protected] rescue true))
    end

    def handle_exception(e)
      if TwitterApiStatus.too_many_requests?(e) ||
          ServiceStatus.retryable_error?(e) ||
          (e.cause && ServiceStatus.retryable_error?(e.cause))
        []
      else
        raise e
      end
    end
  end
end
