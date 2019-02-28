# == Schema Information
#
# Table name: delete_tweets_requests
#
#  id          :bigint(8)        not null, primary key
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  session_id  :string(191)      not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_delete_tweets_requests_on_created_at  (created_at)
#  index_delete_tweets_requests_on_user_id     (user_id)
#

class DeleteTweetsRequest < ApplicationRecord
  belongs_to :user

  def finished!
    update!(finished_at: Time.zone.now) if finished_at.nil?
  end

  def finished?
    !finished_at.nil?
  end

  def perform!(timeout_seconds: 60, loop_limit: 1)
    client = user.api_client.twitter
    destroy_count = 0

    Timeout.timeout(timeout_seconds) do
      loop_limit.times do |n|
        tweets = client.user_timeline(count: 200).select {|t| t.created_at < created_at}
        break if tweets.empty?

        tweets.each do |tweet|
          begin
            client.destroy_status(tweet.id)
            destroy_count += 1
          rescue Twitter::Error::NotFound => e
            raise unless e.message == 'No status found with that ID.'
          end
        end

        raise LoopCountLimitExceeded.new("Loop index #{n}, destroy count #{destroy_count}") if n == loop_limit - 1
      end
    end

    destroy_count
  end

  class LoopCountLimitExceeded < StandardError
  end
end
