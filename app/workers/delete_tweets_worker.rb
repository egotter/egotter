require 'timeout'

class DeleteTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(values)
    destroy_count = 0
    user = User.find(values['user_id'])
    uid = user.uid.to_i
    log = DeleteTweetsLog.new(session_id: values['session_id'], user_id: user.id, uid: uid, screen_name: user.screen_name)

    if !values['skip_recently_enqueued'] && Util::DeleteTweetsRequests.exists?(uid)
      log.update(status: false, message: "[#{uid}] is recently enqueued.")
      return
    end
    Util::DeleteTweetsRequests.add(uid)

    unless user.authorized?
      log.update(status: false, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    client = user.api_client
    t_user = client.user

    if t_user[:statuses_count] == 0
      log.update(status: true, message: "[#{user.screen_name}] hasn't tweeted.")
      return
    end

    destroy_count = destroy_tweets(client, log, values)

    if destroy_count == 0
      log.update(status: true, message: "Tweets are not destroyed.")
    else
      log.update(status: true, message: "#{destroy_count} tweets are destroyed.")
    end

  rescue => e
    handle_error(e, log, values)
  end

  private

  def destroy_tweets(client, log, values)
    destroy_count = 0
    internal_client = client.twitter

    timeout_seconds = 600
    loop_count = 2

    Timeout.timeout(timeout_seconds) do
      loop_count.times do |n|
        tweets = internal_client.user_timeline(count: 200)
        break if tweets.empty?

        tweets.each do |tweet|
          internal_client.destroy_status(tweet.id)
          destroy_count += 1
        end

        raise LoopCountLimitExceeded.new("Loop index #{n}") if n == loop_count - 1
      end
    end

    destroy_count

  rescue Twitter::Error::TooManyRequests => e
    DeleteTweetsWorker.perform_in(e.rate_limit.reset_in.to_i, values.merge(skip_recently_enqueued: true))
    handle_error(e, log, values)
    destroy_count
  rescue Timeout::Error, LoopCountLimitExceeded => e
    handle_error(e, log, values)
    DeleteTweetsWorker.perform_in(60, values.merge(skip_recently_enqueued: true))
    destroy_count
  end

  def handle_error(e, log, values)
    error_message = e.message.truncate(100)
    logger.warn "#{e.class} #{error_message} #{values.inspect}"
    log.update(status: false, error_class: e.class, error_message: error_message)
  end

  class LoopCountLimitExceeded < StandardError; end

end
