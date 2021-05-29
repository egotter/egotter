class TwitterUserFetcher
  attr_reader :api_name

  # client: An instance of ApiClient with :null_store
  def initialize(client, uid, screen_name, fetch_friends, search_for_yourself, reporting)
    @client = ClientWrapper.new(client)
    @uid = uid
    @search_query = "@#{screen_name}"
    @fetch_friends = fetch_friends
    @search_for_yourself = search_for_yourself
    @reporting = reporting
    @mutex = Mutex.new
  end

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch
    result = {}

    if @fetch_friends
      result[:friend_ids] = @client.friend_ids(@uid)
      result[:follower_ids] = @client.follower_ids(@uid)
    end

    if @search_for_yourself
      result[:mentions_timeline] = @client.mentions_timeline
    else
      result[:search] = @client.search(@search_query)
    end

    unless @reporting
      result[:user_timeline] = @client.user_timeline(@uid)
    end

    result[:favorites] = @client.favorites(@uid)

    result
  end

  def fetch_in_threads
    threads = []
    result = Queue.new

    if @fetch_friends
      threads << Thread.new { result << [:friend_ids, bm(:friend_ids) { @client.friend_ids(@uid) }] }
      threads << Thread.new { result << [:follower_ids, bm(:follower_ids) { @client.follower_ids(@uid) }] }
    end

    if @search_for_yourself
      threads << Thread.new { result << [:mentions_timeline, bm(:mentions_timeline) { @client.mentions_timeline }] }
    else
      threads << Thread.new { result << [:search, bm(:search) { @client.search(@search_query) }] }
    end

    unless @reporting
      threads << Thread.new { result << [:user_timeline, bm(:user_timeline) { @client.user_timeline(@uid) }] }
    end

    threads << Thread.new { result << [:favorites, bm(:favorites) { @client.favorites(@uid) }] }

    threads.each(&:join)

    result.size.times.map { result.pop }.to_h
  end

  private

  class ClientWrapper
    def initialize(client)
      @client = client
      @ids_client = client.twitter
    end

    def friend_ids(uid)
      collect_with_max_id do |options|
        @ids_client.friend_ids(uid, options)
      end
    end

    def follower_ids(uid)
      collect_with_max_id do |options|
        @ids_client.follower_ids(uid, options)
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

    private

    def collect_with_max_id(&block)
      options = {count: 5000, cursor: -1}
      collection = []
      calls_count = 0

      50.times do
        begin
          raise Twitter::Error::TooManyRequests if (calls_count += 1) > 5
          response = yield(options)
        rescue => e
          if TwitterApiStatus.too_many_requests?(e)
            @ids_client = Bot.api_client.twitter
            calls_count = 0
            Rails.logger.info 'TwitterUserFetcher::ClientWrapper: Client is reloaded.'
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

  module Instrumentation
    def bm(message, &block)
      start = Time.zone.now
      result = yield
      @mutex.synchronize do
        @bm[message] = Time.zone.now - start if @bm
      end
      result
    end

    def fetch_in_threads(*args, &blk)
      @bm = {}
      start = Time.zone.now

      result = super

      elapsed = Time.zone.now - start
      @bm['sum'] = @bm.values.sum
      @bm['elapsed'] = elapsed
      @bm.transform_values! { |v| sprintf("%.3f", v) }

      Rails.logger.info "Benchmark TwitterUserFetcher uid=#{@uid} #{@bm.inspect}"

      result
    end
  end
  prepend Instrumentation
end
