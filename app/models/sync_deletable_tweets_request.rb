# == Schema Information
#
# Table name: sync_deletable_tweets_requests
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sync_deletable_tweets_requests_on_created_at  (created_at)
#  index_sync_deletable_tweets_requests_on_user_id     (user_id)
#
class SyncDeletableTweetsRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
end
