class DeleteTweetsLogDecorator < ApplicationDecorator
  delegate_all

  def message_for_view
    url = h.sign_in_path(via: h.current_via('error_log'), redirect_path: h.delete_tweets_path(via: h.current_via('error_log')))
    values = {user: h.current_user.screen_name, count: object.destroy_count, retry_in: object.retry_in, url: url}

    if object.message.blank?
      if object.error_class.blank?
        message = I18n.t('delete_tweets.log.errors.default_html', values)
      else
        case object.error_class.demodulize
        when 'Continue'
          message = I18n.t('delete_tweets.log.errors.Continue_html', values)
        when 'TweetsNotFound'
          message = I18n.t('delete_tweets.log.errors.TweetsNotFound_html', values)
        when 'InvalidToken'
          message = I18n.t('delete_tweets.log.errors.InvalidToken_html', values)
        when 'TooManyRequests'
          message = I18n.t('delete_tweets.log.errors.TooManyRequests_html', values)
        when 'Timeout'
          message = I18n.t('delete_tweets.log.errors.Timeout_html', values)
        when 'Unknown'
          message = I18n.t('delete_tweets.log.errors.Unknown_html', values)
        else
          message = I18n.t('delete_tweets.log.errors.default_html', values)
        end
      end
    else
      message = object.message
    end

    message
  end

  def time_for_view
    time = object.created_at.in_time_zone('Tokyo')
    if time.today?
      I18n.l(time, format: :delete_tweets_short)
    else
      I18n.l(time, format: :delete_tweets_long)
    end
  end
end
