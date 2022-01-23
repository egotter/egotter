# == Schema Information
#
# Table name: delete_tweets_by_archive_requests
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :integer          not null
#  archive_name       :string(191)
#  since_date         :datetime
#  until_date         :datetime
#  reservations_count :integer          default(0), not null
#  deletions_count    :integer          default(0), not null
#  errors_count       :integer          default(0), not null
#  started_at         :datetime
#  stopped_at         :datetime
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
  validates :archive_name, presence: true, format: {with: S3::ArchiveData::FILENAME_REGEXP}

  def perform(tweets, threads: 4)
    client = user.api_client.twitter
    update(started_at: Time.zone.now)
    delete_tweets(client, tweets, threads)
    update(finished_at: Time.zone.now)
  end

  def stopped?
    stopped_at
  end

  private

  def delete_tweets(client, tweets, threads_count)
    mx = Mutex.new
    consecutive_errors_count = 0

    tweets.each_slice(threads_count) do |partial_tweets|
      errors = []

      threads = partial_tweets.map do |tweet|
        Thread.new do
          client.destroy_status(tweet.id)
          consecutive_errors_count = 0 if consecutive_errors_count > 0
        rescue => e
          mx.synchronize do
            errors << e
            consecutive_errors_count += 1
          end
          puts "#{e.inspect} tweet_id=#{tweet.id}"
        end
      end
      threads.each(&:join)

      increment!(:deletions_count, partial_tweets.size - errors.size)
      increment!(:errors_count, errors.size) if errors.any?
      processed_count = deletions_count + errors_count

      if processed_count % 1000 == 0 || tweets[-1] == partial_tweets[-1]
        puts progress(started_at, reservations_count, processed_count, deletions_count, errors_count)
      end

      if errors.any? { |e| TwitterApiStatus.invalid_or_expired_token?(e) } ||
          stop_processing?(processed_count, errors_count) ||
          consecutive_errors_count > 100
        puts 'Stop processing'
        update(stopped_at: Time.zone.now)
      end

      break if stopped_at
    end
  end

  def stop_processing?(processed_count, errors_count)
    errors_count > [processed_count, 1000].max / 10
  end

  def progress(started_time, reservations_count, processed_count, deletions_count, errors_count)
    time = Time.zone.now - started_time
    "total #{reservations_count}, processed #{processed_count}, deletions #{deletions_count}, errors #{errors_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / processed_count)}"
  end
end
