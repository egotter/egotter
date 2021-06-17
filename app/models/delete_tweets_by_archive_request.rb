# == Schema Information
#
# Table name: delete_tweets_by_archive_requests
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :integer          not null
#  since_date         :datetime
#  until_date         :datetime
#  reservations_count :integer          default(0), not null
#  deletions_count    :integer          default(0), not null
#  finished_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_delete_tweets_by_archive_requests_on_created_at  (created_at)
#  index_delete_tweets_by_archive_requests_on_user_id     (user_id)
#
class DeleteTweetsByArchiveRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  def perform(tweets, sync: true, threads: 4)
    if sync
      client = user.api_client.twitter
      delete_tweets(client, tweets, threads)
    else
      tweets.each do |tweet|
        DeleteTweetByArchiveWorker.perform_async(id, tweet.id)
      end
    end

    update(finished_at: Time.zone.now)
  end

  private

  def delete_tweets(client, tweets, threads_count)
    started_time = Time.zone.now
    total_size = tweets.size
    processed_count = 0

    tweets.each_slice(threads_count) do |partial_tweets|
      threads = partial_tweets.map { |t| Thread.new { delete_tweet(client, t) } }
      threads.each(&:join)

      if processed_count % 1000 == 0 || tweets[-1] == partial_tweets[-1]
        puts progress(started_time, total_size, processed_count + partial_tweets.size)
      end

      processed_count += partial_tweets.size
      increment!(:deletions_count, partial_tweets.size)
    end
  end

  def delete_tweet(client, tweet)
    DeleteTweetWorker.new.send(:destroy_status!, client, tweet.id)
  end

  def progress(started_time, total_count, processed_count)
    time = Time.zone.now - started_time
    "total #{total_count}, deleted #{processed_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / processed_count)}"
  end
end
