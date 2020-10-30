class TwitterUserFetcher
  attr_reader :api_name

  def initialize(client, uid, screen_name, fetch_friends, search_for_yourself, reporting)
    @client = ClientWrapper.new(client)
    @uid = uid
    @search_query = "@#{screen_name}"
    @fetch_friends = fetch_friends
    @search_for_yourself = search_for_yourself
    @reporting = reporting
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
      threads << Thread.new { result << [:friend_ids, @client.friend_ids(@uid)] }
      threads << Thread.new { result << [:follower_ids, @client.follower_ids(@uid)] }
    end

    if @search_for_yourself
      threads << Thread.new { result << [:mentions_timeline, @client.mentions_timeline] }
    else
      threads << Thread.new { result << [:search, @client.search(@search_query)] }
    end

    unless @reporting
      threads << Thread.new { result << [:user_timeline, @client.user_timeline(@uid)] }
    end

    threads << Thread.new { result << [:favorites, @client.favorites(@uid)] }

    threads.each(&:join)

    result.size.times.map { result.pop }.to_h
  end

  private

  class ClientWrapper
    def initialize(client)
      @client = client
    end

    def friend_ids(uid)
      @client.friend_ids(uid)
    end

    def follower_ids(uid)
      @client.follower_ids(uid)
    end

    def user_timeline(uid)
      @client.user_timeline(uid, include_rts: false)
    end

    def mentions_timeline
      @client.mentions_timeline
    end

    def search(word)
      @client.search(word)
    end

    def favorites(uid)
      @client.favorites(uid)
    end

    module RescueNegligibleError
      %i(user_timeline mentions_timeline favorites).each do |method_name|
        define_method(method_name) do |*args, &blk|
          super(*args, &blk)
        rescue => e
          if TwitterApiStatus.too_many_requests?(e) ||
              ServiceStatus.internal_server_error?(e)
            []
          else
            raise
          end
        end
      end
    end
    prepend RescueNegligibleError
  end
end
