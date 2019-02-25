module S3
  REGION = 'ap-northeast-1'

  module Util
    def bucket_name
      @bucket_name
    end

    def bucket_name=(bucket_name)
      @bucket_name = bucket_name
    end

    def client
      @client ||= Aws::S3::Client.new(region: REGION)
    end

    def where(twitter_user_ids:)
      q = Queue.new
      threads =
          twitter_user_ids.map.with_index do |key, i|
            Thread.new {q.push(i: i, result: find_by(twitter_user_id: key))}
          end
      threads.each(&:join)
      q.size.times.map {q.pop}.sort_by {|item| item[:i]}.map {|item| item[:result]}
    end
  end
end