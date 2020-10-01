# == Schema Information
#
# Table name: delete_tweets_requests
#
#  id            :bigint(8)        not null, primary key
#  session_id    :string(191)      not null
#  user_id       :integer          not null
#  tweet         :boolean          default(FALSE), not null
#  destroy_count :integer          default(0), not null
#  finished_at   :datetime
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_delete_tweets_requests_on_created_at  (created_at)
#  index_delete_tweets_requests_on_user_id     (user_id)
#

class DeleteTweetsRequest < ApplicationRecord
  belongs_to :user
  has_many :logs, -> { order(created_at: :desc) }, primary_key: :id, foreign_key: :request_id, class_name: 'DeleteTweetsLog'

  validates :session_id, presence: true
  validates :user_id, presence: true

  attr_reader :retry_in

  DESTROY_LIMIT = 3200
  FETCH_COUNT = 1000

  before_validation do
    if self.error_class
      self.error_class = self.error_class.truncate(150)
    end

    if self.error_message
      self.error_message = self.error_message.truncate(150)
    end
  end

  def finished!
    if finished_at.nil?
      update!(finished_at: Time.zone.now)
      tweet_finished_message if tweet
      send_finished_message
    end
  end

  def finished?
    !finished_at.nil?
  end

  def processing?
    !finished? && created_at > 1.hour.ago
  end

  def perform!
    @retries = 5

    verify_credentials!
    tweets_exist!
    tweets = fetch_statuses!
    destroy_statuses!(tweets)
  end

  def verify_credentials!
    if user.authorized?
      api_client.verify_credentials
    else
      raise Unauthorized
    end
  rescue => e
    exception_handler(e, __method__)
    @retries -= 1
    retry if @retries > 0
  end

  def tweets_exist!
    if api_client.user.statuses_count == 0
      raise TweetsNotFound
    end
  rescue => e
    exception_handler(e, __method__)
    @retries -= 1
    retry if @retries > 0
  end

  def fetch_statuses!
    tweets = api_client.user_timeline(count: FETCH_COUNT).select { |t| t.created_at < created_at }
    raise TweetsNotFound if tweets.empty?
    tweets
  end

  def destroy_statuses!(tweets)
    tweets.each do |tweet|
      DeleteTweetWorker.perform_async(user_id, tweet.id, request_id: id, last_tweet: tweet == tweets.last)
    end
  end

  def exception_handler(e, last_method = nil)
    if e.is_a?(Error) || e.is_a?(RetryableError)
      raise e
    end

    if e.class == Twitter::Error::TooManyRequests
      raise TooManyRequests.new(last_method, retry_in: e.rate_limit.reset_in.to_i + 1)
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
    api_client.update(Report.finished_tweet(user, self).message)
  rescue => e
    raise FinishedTweetNotSent.new("#{e.class} #{e.message}")
  end

  def send_finished_message
    report = Report.finished_message_from_user(user)
    report.deliver!

    report = Report.finished_message(user, self)
    report.deliver!
  rescue => e
    if !DirectMessageStatus.not_following_you?(e) &&
        !DirectMessageStatus.cannot_send_messages?(e) &&
        !DirectMessageStatus.you_have_blocked?(e)
      raise FinishedMessageNotSent.new("#{e.inspect} sender_uid=#{report.sender.uid}")
    end
  end

  def send_error_message
    report = Report.finished_message_from_user(user)
    report.deliver!

    report = Report.error_message(user)
    report.deliver!
  rescue => e
    raise ErrorMessageNotSent.new("#{e.inspect} sender_uid=#{report.sender.uid}")
  end

  def api_client
    user.api_client.twitter
  end

  class Report
    attr_reader :message, :sender

    def initialize(sender, recipient, message)
      @sender = sender
      @recipient = recipient
      @message = message
    end

    def deliver!
      @sender.api_client.create_direct_message_event(@recipient.uid, @message)
    end

    class << self
      def finished_tweet(user, request)
        template = Rails.root.join('app/views/delete_tweets/finished_tweet.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            destroy_count: request.destroy_count,
            url: delete_tweets_url('delete_tweets_finished_tweet'), kaomoji: Kaomoji.unhappy)
        new(nil, nil, message)
      end

      def finished_message(user, request)
        template = Rails.root.join('app/views/delete_tweets/finished.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            destroy_count: request.destroy_count,
            destroy_limit: DESTROY_LIMIT,
            url: delete_tweets_url('delete_tweets_finished_dm'),
            mypage_url: delete_tweets_mypage_url('delete_tweets_finished_dm')
        )
        new(User.egotter, user, message)
      end

      def finished_message_from_user(user)
        template = Rails.root.join('app/views/delete_tweets/finished_from_user.ja.text.erb')
        message = ERB.new(template.read).result
        new(user, User.egotter, message)
      end

      def error_message(user)
        template = Rails.root.join('app/views/delete_tweets/not_finished.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(url: delete_tweets_url('delete_tweets_error_dm'))
        new(User.egotter, user, message)
      end
    end

    module UrlHelpers
      def delete_tweets_url(via)
        Rails.application.routes.url_helpers.delete_tweets_url(via: via, og_tag: 'false')
      end

      def delete_tweets_mypage_url(via)
        Rails.application.routes.url_helpers.delete_tweets_mypage_url(via: via, og_tag: 'false')
      end
    end
    extend UrlHelpers
  end

  class Error < StandardError
  end

  class RetryableError < StandardError
    attr_reader :retry_in

    def initialize(message, retry_in:)
      super(message)
      @retry_in = retry_in
    end
  end

  class AlreadyFinished < Error; end

  class Unauthorized < Error; end

  class InvalidToken < Error; end

  class TweetsNotFound < Error; end

  class TooManyRequests < RetryableError; end

  class Continue < RetryableError; end

  class FinishedMessageNotSent < Error; end

  class ErrorMessageNotSent < Error; end

  class FinishedTweetNotSent < Error; end

  class RetryExhausted < Error; end

  class Unknown < Error; end
end
