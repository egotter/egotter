# == Schema Information
#
# Table name: delete_tweets_requests
#
#  id                 :bigint(8)        not null, primary key
#  session_id         :string(191)
#  request_token      :string(191)
#  user_id            :integer          not null
#  since_date         :datetime
#  until_date         :datetime
#  send_dm            :boolean          default(FALSE), not null
#  tweet              :boolean          default(FALSE), not null
#  reservations_count :integer          default(0), not null
#  destroy_count      :integer          default(0), not null
#  errors_count       :integer          default(0), not null
#  last_tweet         :bigint(8)
#  started_at         :datetime
#  stopped_at         :datetime
#  finished_at        :datetime
#  error_class        :string(191)      default(""), not null
#  error_message      :text(65535)
#  tweet_ids          :json
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_delete_tweets_requests_on_created_at  (created_at)
#  index_delete_tweets_requests_on_user_id     (user_id)
#

class DeleteTweetsRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  attr_reader :retry_in

  DESTROY_LIMIT = 3200
  MAX_DELETION = 1_300_000

  before_validation do
    if self.request_token.nil?
      self.request_token = SecureRandom.hex(3)
    end

    if self.error_class
      self.error_class = self.error_class.truncate(150)
    end

    if self.error_message
      self.error_message = self.error_message.truncate(150)
    end
  end

  START_DELAY = 3.minutes
  REQUEST_TOKEN_EXPIRY = 10.minutes

  class << self
    def find_by_token(token)
      where('created_at > ?', REQUEST_TOKEN_EXPIRY.ago).find_by(request_token: token, started_at: nil, finished_at: nil, error_message: nil)
    end

    def find_token(user_id)
      where('created_at > ?', REQUEST_TOKEN_EXPIRY.ago).where.not(request_token: nil).find_by(user_id: user_id, started_at: nil, finished_at: nil, error_message: nil)
    end
  end

  # TODO Remove later
  def finished!
    if finished_at.nil?
      update!(finished_at: Time.zone.now)
      tweet_finished_message if tweet
      send_finished_message if send_dm
    end
  end

  # TODO Remove later
  def finished?
    !finished_at.nil?
  end

  def processing?
    !finished_at && created_at > 1.hour.ago
  end

  def perform
    return if started_at || stopped_at || finished_at

    @retries = 5
    update(started_at: Time.zone.now)

    verify_credentials!
    tweets_exist!
    tweets = fetch_statuses!
    tweets = filter_statuses!(tweets)
    update!(reservations_count: tweets.size)
    filtered_tweets_exist!(tweets)
    destroy_statuses!(tweets)

    # Not finished yet
  rescue TweetsNotFound => e
    update(finished_at: Time.zone.now, error_class: e.class, error_message: e.message)
    SendDeleteTweetsFinishedMessageWorker.perform_async(id)
  rescue => e
    update(stopped_at: Time.zone.now, error_class: e.class, error_message: e.message)

    unless [Unauthorized, InvalidToken, TemporarilyLocked].include?(e.class)
      send_error_message
    end

    unless [Unauthorized, InvalidToken, TemporarilyLocked, TooManyRequests].include?(e.class)
      raise
    end
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

  def tweets_exist!
    if api_client.user.statuses_count == 0
      raise TweetsNotFound
    end
  rescue => e
    exception_handler(e, __method__)
    retry if (@retries -= 1) > 0
  end

  def filtered_tweets_exist!(tweets)
    raise TweetsNotFound if tweets.empty?
  end

  def fetch_statuses!
    tweets = []
    max_id = nil
    options = {count: 200}

    # Get all tweets at once
    30.times do
      options[:max_id] = max_id unless max_id.nil?
      response = api_client.user_timeline(options)
      break if response.nil? || response.empty?

      tweets.concat(response)
      max_id = response.last.id - 1
    end

    tweets.select! { |t| t.created_at < created_at }
    raise TweetsNotFound if tweets.empty?

    tweets
  end

  def filter_statuses!(tweets)
    return tweets if !since_date && !until_date

    tweets.reject do |tweet|
      (since_date && tweet.created_at < since_date) ||
          (until_date && tweet.created_at > until_date)
    end
  end

  def destroy_statuses!(tweets)
    tweets.each.with_index do |tweet, i|
      interval = (0.1 * i).floor
      options = {request_id: id, last_tweet: tweet == tweets.last}.reject { |_, v| !v }
      DeleteTweetWorker.perform_in(interval, user_id, tweet.id, options)
    end

    begin
      update(last_tweet: tweets.last.id, tweet_ids: tweets.map(&:id))
    rescue => e
      update(last_tweet: tweets.last.id)
    end
  end

  def too_many_errors?
    reservations_count > 100 && errors_count > 10 && errors_count > reservations_count / 10
  end

  def exception_handler(e, last_method = nil)
    if e.is_a?(Error)
      raise e
    end

    if e.class == Twitter::Error::TooManyRequests
      raise TooManyRequests.new(last_method.to_s)
    elsif TwitterApiStatus.unauthorized?(e)
      raise InvalidToken.new(e.message)
    elsif TwitterApiStatus.temporarily_locked?(e)
      raise TemporarilyLocked.new(e.message)
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
    message = DeleteTweetsReport.finished_tweet(user, self).message
    api_client.update(message)
    SlackBotClient.channel('monit_delete_tweets_tweet').post_message("`Bulk` request_id=#{id} tweet=#{message}") rescue nil
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
      DeleteTweetsReport.finished_message_from_user(user).deliver!
    end
  rescue => e
    Airbag.warn "#{self.class}##{__method__}: #{e.inspect}", request_id: id
  end

  def send_result_message
    DeleteTweetsReport.finished_message(user, destroy_count).deliver!
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
    report = DeleteTweetsReport.finished_message_from_user(user)
    begin
      report.deliver!
    rescue => e
      raise e unless TwitterApiStatus.temporarily_locked?(e)
    end

    report = DeleteTweetsReport.error_message(user)
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
        statuses_count: user.persisted_statuses_count,
        valid_subscription: user.has_valid_subscription? ? '`true`' : 'false',
    }.map { |k, v| "#{k}=#{v}" }.join(' ')
  end

  class Error < StandardError
  end

  # TODO Remove later
  class AlreadyFinished < Error; end

  class Unauthorized < Error; end

  class InvalidToken < Error; end

  class TweetsNotFound < Error; end

  class TooManyRequests < Error; end

  class TemporarilyLocked < Error; end

  class FinishedMessageNotSent < Error; end

  class ErrorMessageNotSent < Error; end

  class FinishedTweetNotSent < Error; end

  class RetryExhausted < Error; end

  class Unknown < Error; end
end
