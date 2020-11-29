# == Schema Information
#
# Table name: delete_favorites_requests
#
#  id            :bigint(8)        not null, primary key
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
#  index_delete_favorites_requests_on_created_at  (created_at)
#  index_delete_favorites_requests_on_user_id     (user_id)
#
class DeleteFavoritesRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  DESTROY_LIMIT = 3200

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
    favorites_exist!
    tweets = fetch_favorites!
    destroy_favorites!(tweets)
  end

  def verify_credentials!
    if user.authorized?
      api_client.verify_credentials
    else
      raise Unauthorized
    end
  rescue => e
    unless TwitterApiStatus.too_many_requests?(e)
      exception_handler(e, __method__)
      retry if (@retries -= 1) > 0
    end
  end

  def favorites_exist!
    if api_client.user(user.uid).favourites_count == 0
      raise FavoritesNotFound
    end
  rescue => e
    exception_handler(e, __method__)
    retry if (@retries -= 1) > 0
  end

  def fetch_favorites!
    tweets = []
    max_id = nil
    options = {count: 200}

    5.times do
      options[:max_id] = max_id unless max_id.nil?
      response = api_client.favorites(options)
      break if response.nil? || response.empty?

      tweets.concat(response)
      max_id = response.last.id - 1
    end

    tweets.select! { |t| t.created_at < created_at }
    raise FavoritesNotFound if tweets.empty?

    tweets
  end

  def destroy_favorites!(tweets)
    tweets.each do |tweet|
      DeleteFavoriteWorker.perform_async(user_id, tweet.id, request_id: id, last_tweet: tweet == tweets.last)
    end
  end

  def exception_handler(e, last_method = nil)
    if e.is_a?(Error) || e.is_a?(RetryableError)
      raise e
    end

    if e.class == Twitter::Error::TooManyRequests
      raise TooManyRequests.new(last_method, retry_in: e.rate_limit.reset_in.to_i + 1)
    elsif TwitterApiStatus.unauthorized?(e)
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
    message = DeleteFavoritesReport.finished_tweet(user, self).message
    api_client.update(message)
    SendMessageToSlackWorker.perform_async(:delete_favorites, "request_id=#{id} tweet=#{message}")
  rescue => e
    raise FinishedTweetNotSent.new("#{e.class} #{e.message}")
  end

  def send_finished_message
    report = DeleteFavoritesReport.finished_message_from_user(user)
    report.deliver!

    report = DeleteFavoritesReport.finished_message(user, self)
    report.deliver!
  rescue => e
    if !DirectMessageStatus.not_following_you?(e) &&
        !DirectMessageStatus.cannot_send_messages?(e) &&
        !DirectMessageStatus.you_have_blocked?(e)
      raise FinishedMessageNotSent.new("#{e.inspect} sender_uid=#{report.sender.uid}")
    end
  end

  def send_error_message
    report = DeleteFavoritesReport.finished_message_from_user(user)
    report.deliver!

    report = DeleteFavoritesReport.error_message(user)
    report.deliver!
  rescue => e
    raise ErrorMessageNotSent.new("#{e.inspect} sender_uid=#{report.sender.uid}")
  end

  def api_client
    user.api_client.twitter
  end

  def to_message
    {
        request_id: id,
        destroy_count: destroy_count,
        user_id: user.id,
        screen_name: user.screen_name,
        favorites_count: user.persisted_favorites_count,
        valid_subscription: user.has_valid_subscription? ? '`true`' : 'false',
    }.map { |k, v| "#{k}=#{v}" }.join(' ')
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

  class FavoritesNotFound < Error; end

  class TooManyRequests < RetryableError; end

  class FinishedMessageNotSent < Error; end

  class ErrorMessageNotSent < Error; end

  class FinishedTweetNotSent < Error; end

  class RetryExhausted < Error; end

  class Unknown < Error; end
end