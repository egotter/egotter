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
    errors = {total: [], consecutive: [], current: []}
    lock = Mutex.new

    tweets.each_slice(threads_count) do |partial_tweets|
      errors[:current] = []

      partial_tweets.map do |tweet|
        Thread.new(client, tweet) do |clt, twt|
          clt.destroy_status(twt.id)
        rescue => e
          lock.synchronize do
            errors[:current] << e
            errors[:consecutive] << e
            errors[:total] << e
            puts "#{e.inspect} tweet_id=#{twt.id} consecutive=#{errors[:consecutive].size} total=#{errors[:total].size}"
          end
        end
      end.each(&:join)

      if errors[:current].empty?
        errors[:consecutive].clear
      end

      increment!(:deletions_count, partial_tweets.size - errors[:current].size)
      increment!(:errors_count, errors[:current].size) if errors[:current].any?

      processed_count = deletions_count + errors_count

      if processed_count % 1000 == 0 || tweets[-1] == partial_tweets[-1]
        puts progress(started_at, reservations_count, processed_count, deletions_count, errors_count)
      end

      if errors[:current].any? { |e| TwitterApiStatus.invalid_or_expired_token?(e) } ||
          (errors_count > [processed_count, 1000].max / 10) ||
          errors[:consecutive].size > 100
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
