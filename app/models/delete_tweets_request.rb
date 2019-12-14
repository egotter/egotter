# == Schema Information
#
# Table name: delete_tweets_requests
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      not null
#  user_id     :integer          not null
#  tweet       :boolean          default(FALSE), not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_delete_tweets_requests_on_created_at  (created_at)
#  index_delete_tweets_requests_on_user_id     (user_id)
#

class DeleteTweetsRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user
  has_many :logs, -> { order(created_at: :desc) }, primary_key: :id, foreign_key: :request_id, class_name: 'DeleteTweetsLog'

  validates :session_id, presence: true
  validates :user_id, presence: true

  attr_reader :destroy_count, :retry_in

  TIMEOUT_SECONDS = 10
  RETRY_INTERVAL = 10

  FETCH_COUNT = 100
  THREADS_NUM = 3

  def perform!
    error_check! unless @error_check

    @destroy_count ||= 0

    ::Timeout.timeout(TIMEOUT_SECONDS) do
      tweets = api_client.user_timeline(count: FETCH_COUNT).select { |t| t.created_at < created_at }
      raise TweetsNotFound if tweets.empty?

      Parallel.each(tweets, in_threads: THREADS_NUM) do |tweet|
        destroy_status!(tweet.id)
        @destroy_count += 1
      end
    end

    raise Continue.new(retry_in: RETRY_INTERVAL, destroy_count: destroy_count)

  rescue Twitter::Error::InternalServerError => e
    retry
  rescue Twitter::Error::TooManyRequests => e
    raise TooManyRequests.new(retry_in: e.rate_limit.reset_in.to_i + 1, destroy_count: destroy_count)
  rescue ::Timeout::Error => e
    raise Timeout.new(retry_in: RETRY_INTERVAL, destroy_count: destroy_count)
  rescue => e
    if e.message.include?('Connection reset by peer')
      raise ConnectionResetByPeer.new(retry_in: RETRY_INTERVAL, destroy_count: destroy_count)
    else
      raise
    end
  end

  def error_check!
    raise Unauthorized unless user.authorized?

    begin
      api_client.verify_credentials
    rescue Twitter::Error::TooManyRequests => e
      raise TooManyRequests.new(retry_in: e.rate_limit.reset_in.to_i + 1, destroy_count: 0)
    rescue => e
      if e.message == 'Invalid or expired token.'
        raise InvalidToken.new(e.message)
      else
        raise Unknown.new("#{e.class} #{e.message}")
      end
    end

    raise TweetsNotFound if api_client.user[:statuses_count] == 0

    @error_check = true
  end

  def destroy_status!(tweet_id)
    api_client.destroy_status(tweet_id)
  rescue Twitter::Error::NotFound => e
    raise unless e.message == 'No status found with that ID.'
  end

  def tweet_finished_message
    url = Rails.application.routes.url_helpers.delete_tweets_url(via: 'delete_tweets_finished_tweet')
    api_client.update(I18n.t('delete_tweets.tweet.message', url: url, kaomoji: Kaomoji.unhappy))
  rescue => e
    raise FinishedTweetNotSent.new("#{e.class} #{e.message}")
  end

  def send_finished_message(sender)
    url = Rails.application.routes.url_helpers.delete_tweets_url(via: 'delete_tweets_finished_dm')
    dm_client(sender).create_direct_message(user.uid, I18n.t('delete_tweets.dm.message', url: url))
  rescue => e
    raise FinishedMessageNotSent.new("#{e.class} #{e.message}")
  end

  def send_error_message(sender)
    url = Rails.application.routes.url_helpers.delete_tweets_url(via: 'delete_tweets_error_dm')
    dm_client(sender).create_direct_message(user.uid, I18n.t('delete_tweets.dm.error_message', url: url))
  rescue => e
    raise ErrorMessageNotSent.new("#{e.class} #{e.message}")
  end

  def api_client
    user.api_client.twitter
  end

  def dm_client(sender)
    DirectMessageClient.new(sender.api_client.twitter)
  end

  class Error < StandardError
  end

  class Retryable < StandardError
    attr_reader :retry_in, :destroy_count

    def initialize(retry_in:, destroy_count:)
      super('')
      @retry_in = retry_in
      @destroy_count = destroy_count
    end
  end

  class AlreadyFinished < Error
  end

  class Unauthorized < Error
  end

  class InvalidToken < Error
  end

  class TweetsNotFound < Error
  end

  class Timeout < Retryable
  end

  class TooManyRequests < Retryable
  end

  class Continue < Retryable
  end

  class ConnectionResetByPeer < Retryable
  end

  class FinishedMessageNotSent < Error
  end

  class ErrorMessageNotSent < Error
  end

  class FinishedTweetNotSent < Error
  end

  class Unknown < Error
  end
end
