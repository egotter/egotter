# == Schema Information
#
# Table name: delete_tweets_requests
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      not null
#  user_id     :integer          not null
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

  def perform!(timeout_seconds: 10)
    Timeout.timeout(timeout_seconds) do
      do_perform!
    end
  rescue Timeout::Error => e
    @timeout = true
    logger.info "#{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def timeout?
    @timeout ||= false
  end

  def too_many_requests?
    @too_many_requests ||= false
  end

  def error
    @error
  end

  def tweets_not_found?
    @tweets_not_found ||= false
  end

  def destroy_count
    @destroy_count ||= 0
  end

  def send_finished_message
    dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
    dm_client.create_direct_message(user.uid, I18n.t('delete_tweets.new.dm_messge'))
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  def send_error_message
    dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
    url = Rails.application.routes.url_helpers.delete_tweets_url
    dm_client.create_direct_message(user.uid, I18n.t('delete_tweets.new.dm_error_messge', url: url))
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  private

  def do_perform!
    tweets = client.user_timeline(count: 100).select {|t| t.created_at < created_at}
    if tweets.empty?
      @tweets_not_found = true
      return
    end

    @destroy_count = 0

    Parallel.each(tweets, in_threads: 3) do |tweet|
      destroy_status!(tweet.id)
      @destroy_count += 1
    end

  rescue Twitter::Error::TooManyRequests => e
    @too_many_requests = true
    @error = e
    logger.warn "#{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def destroy_status!(tweet_id)
    client.destroy_status(tweet_id)
  rescue Twitter::Error::NotFound => e
    raise unless e.message == 'No status found with that ID.'
  end

  def client
    @client ||= user.api_client.twitter
  end
end
