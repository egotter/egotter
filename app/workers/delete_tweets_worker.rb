require 'timeout'

class DeleteTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(values)
    values = values.with_indifferent_access
    DeleteTweetsRequest.find(values['request_id']).user_id
  end

  def after_skip(values)
    logger.warn "Skipped #{values.inspect}"
  end

  def perform(values)
    destroy_count = 0
    request = DeleteTweetsRequest.find(values['request_id'])
    user = request.user
    log = DeleteTweetsLog.create!(user_id: user.id, request_id: request.id)

    unless user.authorized?
      log.update(status: false, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    if user.api_client.user[:statuses_count] == 0
      log.update(status: true, message: "[#{user.screen_name}] hasn't tweeted.")
      request.finished!
      return
    end

    begin
      destroy_count = request.perform!
    rescue Twitter::Error::TooManyRequests => e
      DeleteTweetsWorker.perform_in(e.rate_limit.reset_in.to_i, values.merge(skiq_unique: true))
      save_error(e, log, values)
    rescue Timeout::Error, DeleteTweetsRequest::LoopCountLimitExceeded => e
      save_error(e, log, values)
      DeleteTweetsWorker.perform_in(60, values.merge(skiq_unique: true))
    else
      log.update(status: true, message: "#{destroy_count} tweets are destroyed.")
      request.finished!
      notify(user)
    end

  rescue => e
    save_error(e, log, values)
  end

  private

  def notify(user)
    DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, user.uid, I18n.t('delete_tweets.new.dm_messge')).perform
  end

  def save_error(e, log, values)
    error_message = e.message.truncate(100)
    level = e.class == DeleteTweetsRequest::LoopCountLimitExceeded ? :info : :warn
    logger.send(level, "#{e.class} #{error_message} #{values.inspect}")
    log.update(status: false, error_class: e.class, error_message: error_message)
  end
end
