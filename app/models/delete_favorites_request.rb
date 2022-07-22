# == Schema Information
#
# Table name: delete_favorites_requests
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :integer          not null
#  since_date         :datetime
#  until_date         :datetime
#  send_dm            :boolean          default(FALSE), not null
#  tweet              :boolean          default(FALSE), not null
#  reservations_count :integer          default(0), not null
#  destroy_count      :integer          default(0), not null
#  errors_count       :integer          default(0), not null
#  stopped_at         :datetime
#  finished_at        :datetime
#  error_class        :string(191)      default(""), not null
#  error_message      :text(65535)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
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
      send_finished_message if send_dm
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
    tweets = filter_favorites!(tweets)
    update!(reservations_count: tweets.size)
    filtered_favorites_exist!(tweets)
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

  def filtered_favorites_exist!(tweets)
    raise FavoritesNotFound if tweets.empty?
  end

  def fetch_favorites!
    tweets = []
    max_id = nil
    options = {count: 200}

    # Get all favorites at once
    30.times do
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

  def filter_favorites!(tweets)
    return tweets if !since_date && !until_date

    tweets.reject do |tweet|
      (since_date && tweet.created_at < since_date) ||
          (until_date && tweet.created_at > until_date)
    end
  end

  def destroy_favorites!(tweets)
    tweets.each.with_index do |tweet, i|
      interval = (0.1 * i).floor
      DeleteFavoriteWorker.perform_in(interval, user_id, tweet.id, request_id: id, last_tweet: tweet == tweets.last)
    end
  end

  def too_many_errors?
    reservations_count > 100 && errors_count > 10 && errors_count > reservations_count / 10
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

  # TODO "Twitter::Error::Unauthorized Could not authenticate you." will happen here.
  # This error occurs together with DeleteTweetsRequest::TweetsNotFound.
  # I need to investigate what kind of messages cause this error.
  def tweet_finished_message
    message = DeleteFavoritesReport.finished_tweet(user, self).message
    api_client.update(message)
    SendMessageToSlackWorker.perform_async(:monit_delete_favorites, "request_id=#{id} tweet=#{message}")
  rescue => e
    if TwitterApiStatus.temporarily_locked?(e)
      # Do nothing
    else
      raise FinishedTweetNotSent.new("exception=#{e.inspect} user_id=#{user_id} message=#{message}")
    end
  end

  def send_finished_message
    send_start_message
    send_result_message
  end

  def send_start_message
    unless DirectMessageReceiveLog.message_received?(user.uid)
      DeleteFavoritesReport.finished_message_from_user(user).deliver!
    end
  rescue => e
    Airbag.warn "#{self.class}##{__method__}: #{e.inspect} request_id=#{id}"
  end

  def send_result_message
    DeleteFavoritesReport.finished_message(user, self).deliver!
  rescue => e
    if DirectMessageStatus.not_following_you?(e) ||
        DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.you_have_blocked?(e)
      # Do nothing
    else
      raise FinishedMessageNotSent.new("#{e.inspect} request_id=#{id}")
    end
  end

  def send_error_message
    report = DeleteFavoritesReport.finished_message_from_user(user)
    begin
      report.deliver!
    rescue => e
      raise e unless TwitterApiStatus.temporarily_locked?(e)
    end

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
        reservations_count: reservations_count,
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
