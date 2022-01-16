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

  def perform(tweets, threads: 4)
    client = user.api_client.twitter
    delete_tweets(client, tweets, threads)
    update(finished_at: Time.zone.now)
  end

  def stopped?
    @stopped
  end

  private

  def delete_tweets(client, tweets, threads_count)
    start_time = Time.zone.now
    total_count = tweets.size
    processed_count = 0
    errors_count = 0
    @stopped = false
    mx = Mutex.new

    tweets.each_slice(threads_count) do |partial_tweets|
      errors = []

      threads = partial_tweets.map do |tweet|
        Thread.new do
          client.destroy_status(tweet.id)
        rescue => e
          mx.synchronize { errors << e }
          puts "#{e.inspect} tweet_id=#{tweet.id}"
        end
      end
      threads.each(&:join)

      increment!(:deletions_count, partial_tweets.size - errors.size)
      # TODO Update #errors_count
      processed_count += partial_tweets.size
      errors_count += errors.size

      if processed_count % 1000 == 0 || tweets[-1] == partial_tweets[-1]
        puts progress(start_time, total_count, processed_count, deletions_count, errors_count)
      end

      if errors.any? { |e| TwitterApiStatus.invalid_or_expired_token?(e) } ||
          stop_processing?(processed_count, errors_count)
        puts 'Stop processing'
        @stopped = true
      end

      break if @stopped
    end

    if @stopped
      # TODO Update #stopped_at
    end
  end

  def stop_processing?(processed_count, errors_count)
    errors_count > [processed_count, 1000].max / 10
  end

  def progress(started_time, total_count, processed_count, deletions_count, errors_count)
    time = Time.zone.now - started_time
    "total #{total_count}, processed #{processed_count}, deletions #{deletions_count}, errors #{errors_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / processed_count)}"
  end
end
