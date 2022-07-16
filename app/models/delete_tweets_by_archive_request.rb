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
    total_errors = Queue.new
    consecutive_errors = Queue.new

    tweets.each_slice(threads_count) do |partial_tweets|
      current_errors = Queue.new

      partial_tweets.map do |tweet|
        Thread.new(client, tweet) do |clt, twt|
          clt.destroy_status(twt.id)
          consecutive_errors = Queue.new if consecutive_errors.size > 0
        rescue => e
          current_errors.push(e)
          consecutive_errors.push(e)
          total_errors.push(e)
          puts "#{e.inspect} tweet_id=#{twt.id} consecutive=#{consecutive_errors.size} total=#{total_errors.size}"
        end
      end.each(&:join)

      increment!(:deletions_count, partial_tweets.size - current_errors.size)
      increment!(:errors_count, current_errors.size) unless current_errors.empty?

      processed_count = deletions_count + errors_count
      errors_any = current_errors.size.times.map { current_errors.pop }

      if processed_count % 1000 == 0 || tweets[-1] == partial_tweets[-1]
        puts progress(started_at, reservations_count, processed_count, deletions_count, errors_count)
      end

      if errors_any.any? { |e| TwitterApiStatus.invalid_or_expired_token?(e) } ||
          (errors_count > [processed_count, 1000].max / 10) ||
          consecutive_errors.size > 100
        puts 'Stop processing'
        update(stopped_at: Time.zone.now)
      end

      break if stopped_at
    end
  end

  def progress(started_time, reservations_count, processed_count, deletions_count, errors_count)
    time = Time.zone.now - started_time
    "total #{reservations_count}, processed #{processed_count}, deletions #{deletions_count}, errors #{errors_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / processed_count)}"
  end
end
