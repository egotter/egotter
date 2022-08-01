class DeleteTweetWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    request = DeleteTweetsRequest.find(options['request_id'])
    return if request.stopped_at

    client = User.find(user_id).api_client.twitter
    destroy_status!(client, tweet_id, request)

    if request.last_tweet == tweet_id || options['last_tweet']
      request.update(finished_at: Time.zone.now)
      SendDeleteTweetsFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      if options['retries']
        Airbag.warn 'Retry exhausted', exception: e.inspect, user_id: user_id, tweet_id: tweet_id, options: options
      else
        self.class.perform_in(rand(10) + 10, user_id, tweet_id, options.merge('retries' => 1))
      end
    else
      Airbag.exception e, user_id: user_id, tweet_id: tweet_id, options: options
    end
  end

  private

  def destroy_status!(client, tweet_id, request)
    client.destroy_status(tweet_id)
    request.increment!(:destroy_count)
  rescue => e
    request.update(error_class: e.class, error_message: e.message)
    request.increment!(:errors_count)

    if request.too_many_errors?
      request.update(stopped_at: Time.zone.now)
    end

    handler = ErrorHandler.new(e)

    if handler.stop?
      request.update(stopped_at: Time.zone.now)
    elsif handler.raise?
      raise
    end
  end

  class << self
    def consume_scheduled_jobs(limit: 10)
      processed_count = 0
      errors_count = 0
      jobs = []

      Sidekiq::ScheduledSet.new.scan(name).each do |job|
        if job.klass == name && job.at > 3.minutes.since
          jobs << job
        end

        if jobs.size >= limit
          break
        end
      end

      jobs.each do |job|
        new.perform(*job.args)
        job.delete
        processed_count += 1
      rescue => e
        puts e.inspect
        errors_count += 1
      end

      if processed_count > 0 || errors_count > 0
        puts "consume_scheduled_jobs: processed=#{processed_count}#{" errors=#{errors_count}" if errors_count > 0}"
      end
    end
  end

  class ErrorHandler
    def initialize(e)
      @e = e
    end

    def noop?
      TweetStatus.no_status_found?(@e) ||
          TweetStatus.not_authorized?(@e) ||
          TweetStatus.that_page_does_not_exist?(@e) ||
          TweetStatus.forbidden?(@e)
    end

    def stop?
      TwitterApiStatus.your_account_suspended?(@e) ||
          TwitterApiStatus.invalid_or_expired_token?(@e) ||
          TwitterApiStatus.suspended?(@e) ||
          TweetStatus.temporarily_locked?(@e) ||
          TwitterApiStatus.might_be_automated?(@e)
    end

    def raise?
      !noop? && !stop?
    end
  end
end
