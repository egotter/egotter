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

  def perform(tweets, sync: true)
    if sync
      started_time = Time.zone.now

      tweets.each.with_index do |tweet, i|
        DeleteTweetByArchiveWorker.new.perform(id, tweet.id)

        if i % 1000 == 0 || i == tweets.size - 1
          print_progress(tweets, started_time, i + 1)
        end
      end
    else
      tweets.each do |tweet|
        DeleteTweetByArchiveWorker.perform_async(id, tweet.id)
      end
    end

    update(finished_at: Time.zone.now)
  end

  private

  def print_progress(tweets, started_time, deleted_count)
    time = Time.zone.now - started_time
    puts "total #{tweets.size}, deleted #{deleted_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / deleted_count)}"
  end
end
