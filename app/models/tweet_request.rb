# == Schema Information
#
# Table name: tweet_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  tweet_id    :bigint(8)
#  text        :string(191)      not null
#  finished_at :datetime
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tweet_requests_on_created_at  (created_at)
#  index_tweet_requests_on_user_id     (user_id)
#

class TweetRequest < ApplicationRecord
  include RequestRunnable
  belongs_to :user

  validates :user_id, presence: true

  before_validation :truncate_text

  def truncate_text
    self.text = self.text.truncate(180) if self.text
  end

  def perform!
    fulltext = text
    fulltext += " #{self.class.share_suffix(user)}" unless fulltext.include?('http')

    tweet = create_status!(fulltext)
    update(tweet_id: tweet.id) if tweet
    tweet
  end

  def create_status!(text)
    retries ||= 1
    client.update!(text)
  rescue => e
    if TwitterApiStatus.could_not_authenticate_you?(e)
      if (retries -= 1) >= 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    elsif TweetStatus.duplicate_status?(e)
      update(deleted_at: Time.zone.now)
      nil
    else
      update(deleted_at: Time.zone.now)
      raise
    end
  end

  def client
    @client ||= user.api_client.twitter
  end

  def to_message(via: nil)
    {
        request_id: id,
        user_id: user.id,
        screen_name: user.screen_name,
        valid_subscription: user.has_valid_subscription? ? '`true`' : 'false',
        text: text,
        url: "https://twitter.com/#{user.screen_name}/status/#{tweet_id}",
        via: via,
    }.merge(SearchCountLimitation.new(user: user, session_id: nil).to_h).map { |k, v| "#{k}=#{v}" }.join(' ')
  end

  class << self
    def share_suffix(user)
      "#egotter #{share_url(user)}"
    end

    def share_url(user)
      Rails.application.routes.url_helpers.root_url(
          utm_source: 'share_tweet',
          utm_medium: 'share_tweet',
          utm_campaign: 'share_tweet',
          via: 'share_tweet',
          click_id: ClickIdGenerator.gen(user)
      )
    end
  end

  class RetryExhausted < StandardError; end

  class TextValidator
    include Twitter::TwitterText::Validation

    def initialize(text)
      @text = text
    end

    def valid?
      @text.present? && !@text.include?('*') && parse_tweet(@text)[:valid]
    end
  end
end
