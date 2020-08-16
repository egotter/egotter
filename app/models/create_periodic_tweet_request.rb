# == Schema Information
#
# Table name: create_periodic_tweet_requests
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_create_periodic_tweet_requests_on_created_at  (created_at)
#  index_create_periodic_tweet_requests_on_user_id     (user_id) UNIQUE
#
class CreatePeriodicTweetRequest < ApplicationRecord
  validates :user_id, presence: true, uniqueness: true
end
