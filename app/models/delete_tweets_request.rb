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

  attr_reader :retry_in

  TIMEOUT_SECONDS = 10
  RETRY_INTERVAL = 10

  FETCH_COUNT = 100
  THREADS_NUM = 3

  def perform!
    @retries = 5

    verify_credentials!
    tweets_exist!
    tweets = fetch_statuses!
    destroy_statuses!(tweets)

    raise Continue.new(retry_in: RETRY_INTERVAL, destroy_count: @destroy_count)
  end

  def verify_credentials!
    if user.authorized?
      api_client.verify_credentials
    else
      raise Unauthorized
    end
  rescue => e
    exception_handler(e)
    @retries -= 1
    retry
  end

  def tweets_exist!
    if api_client.user.statuses_count == 0
      raise TweetsNotFound
    end
  rescue => e
    exception_handler(e)
    @retries -= 1
    retry
  end

  def fetch_statuses!
    tweets = api_client.user_timeline(count: FETCH_COUNT).select { |t| t.created_at < created_at }
    raise TweetsNotFound if tweets.empty?
    tweets
  end

  def destroy_statuses!(tweets, timeout: TIMEOUT_SECONDS)
    start = Time.zone.now

    @destroy_count = 0
    error = nil

    Parallel.each(tweets, in_threads: THREADS_NUM) do |tweet|
      if Time.zone.now - start > timeout
        error = Timeout.new(retry_in: RETRY_INTERVAL, destroy_count: @destroy_count)
        raise Parallel::Break
      end

      begin
        destroy_status!(tweet.id)
      rescue => e
        error = e
        raise Parallel::Break
      end

      @destroy_count += 1
    end

    if error
      raise error
    end

  rescue => e
    exception_handler(e)
    @retries -= 1
    retry
  end

  def destroy_status!(tweet_id)
    api_client.destroy_status(tweet_id)
  rescue Twitter::Error::NotFound => e
    if e.message != 'No status found with that ID.'
      raise
    end
  end

  def exception_handler(e)
    if e.is_a?(Error) || e.is_a?(RetryableError)
      raise e
    end

    if e.class == Twitter::Error::TooManyRequests
      raise TooManyRequests.new(retry_in: e.rate_limit.reset_in.to_i + 1, destroy_count: @destroy_count)
    elsif e.class == ::Timeout::Error
      raise Timeout.new(retry_in: RETRY_INTERVAL, destroy_count: @destroy_count)
    elsif AccountStatus.unauthorized?(e)
      raise InvalidToken.new(e.message)
    elsif ServiceStatus.retryable_error?(e)
      if !@retries.nil? && @retries <= 0
        raise RetryExhausted.new("#{e.class} #{e.message}")
      end
    else
      raise Unknown.new("#{e.class} #{e.message}")
    end
  end

  def tweet_finished_message
    api_client.update(Report.finished_tweet(user).message)
  rescue => e
    raise FinishedTweetNotSent.new("#{e.class} #{e.message}")
  end

  def send_finished_message
    Report.finished_message_from_user(user).deliver!
    Report.finished_message(user).deliver!
  rescue => e
    if !DirectMessageStatus.not_following_you?(e) && !DirectMessageStatus.cannot_send_messages?(e)
      raise FinishedMessageNotSent.new("#{e.class} #{e.message}")
    end
  end

  def send_error_message
    Report.finished_message_from_user(user).deliver!
    Report.error_message(user).deliver!
  rescue => e
    raise ErrorMessageNotSent.new("#{e.class} #{e.message}")
  end

  def api_client
    user.api_client.twitter
  end

  class Report
    attr_reader :message

    def initialize(sender, recipient, message)
      @sender = sender
      @recipient = recipient
      @message = message
    end

    def deliver!
      @sender.api_client.create_direct_message_event(@recipient.uid, @message)
    end

    class << self
      def finished_tweet(user)
        template = Rails.root.join('app/views/delete_tweets/finished_tweet.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            url: current_url('delete_tweets_finished_tweet'), kaomoji: Kaomoji.unhappy)
        new(nil, nil, message)
      end

      def finished_message(user)
        template = Rails.root.join('app/views/delete_tweets/finished.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(url: current_url('delete_tweets_finished_dm'))
        new(User.egotter, user, message)
      end

      def finished_message_from_user(user)
        template = Rails.root.join('app/views/delete_tweets/finished_from_user.ja.text.erb')
        message = ERB.new(template.read).result
        new(user, User.egotter, message)
      end

      def error_message(user)
        template = Rails.root.join('app/views/delete_tweets/not_finished.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(url: current_url('delete_tweets_error_dm'))
        new(User.egotter, user, message)
      end

      def current_url(via)
        delete_tweets_url(via: via, og_tag: 'false')
      end
    end

    module UrlHelpers
      def method_missing(method, *args, &block)
        if method.to_s.end_with?('_url')
          Rails.application.routes.url_helpers.send(method, *args, &block)
        else
          super
        end
      end
    end
    extend UrlHelpers
  end

  class Error < StandardError
  end

  class RetryableError < StandardError
    attr_reader :retry_in, :destroy_count

    def initialize(retry_in:, destroy_count:)
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

  class Timeout < RetryableError
  end

  class TooManyRequests < RetryableError
  end

  class Continue < RetryableError
  end

  class ConnectionResetByPeer < RetryableError
  end

  class FinishedMessageNotSent < Error
  end

  class ErrorMessageNotSent < Error
  end

  class FinishedTweetNotSent < Error
  end

  class RetryExhausted < Error
  end

  class Unknown < Error
  end
end
