module TwitterUserFetcher
  class Fetcher
    def initialize(client, uid, screen_name)
      @client = client
      @uid = uid
      @screen_name = screen_name
    end

    def search_query
      "@#{@screen_name}"
    end

    def fetch
      @client.parallel do |batch|
        method_args.each { |args| batch.send(*args) }
      end
    end
  end

  class SearchOneselfFetcher < Fetcher
    def method_args
      [
          [:friend_ids, @uid],
          [:follower_ids, @uid],
          [:user_timeline, @uid, {include_rts: false}], # replying
          [:mentions_timeline], # replied
          [:favorites, @uid], # favoriting
      ]
    end
  end

  class SearchOneselfWithoutFriendshipsFetcher < Fetcher
    def method_args
      [
          [:user_timeline, @uid, {include_rts: false}], # replying
          [:mentions_timeline], # replied
          [:favorites, @uid], # favoriting
      ]
    end
  end

  class SearchSomeoneFetcher < Fetcher
    def method_args
      [
          [:friend_ids, @uid],
          [:follower_ids, @uid],
          [:user_timeline, @uid, {include_rts: false}], # replying
          [:search, search_query], # replied
          [:favorites, @uid], # favoriting
      ]
    end
  end

  class SearchSomeoneWithoutFriendshipsFetcher < Fetcher
    def method_args
      [
          [:user_timeline, @uid, {include_rts: false}], # replying
          [:search, search_query], # replied
          [:favorites, @uid], # favoriting
      ]
    end
  end

  class PromptReportFetcher < Fetcher
    def method_args
      [
          [:friend_ids, @uid],
          [:follower_ids, @uid],
      ]
    end
  end
end