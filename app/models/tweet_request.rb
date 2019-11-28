# == Schema Information
#
# Table name: tweet_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  text        :string(191)      not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tweet_requests_on_created_at  (created_at)
#  index_tweet_requests_on_user_id     (user_id)
#

class TweetRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user

  validates :user_id, presence: true
  validates :text, format: %r[#{Rails.env.production? ? 'https://egotter\.com' : 'http://localhost:3000'}]

  def perform!
    client.update(text)
  end

  def client
    @client ||= user.api_client.twitter
  end
end
