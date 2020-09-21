class DeleteTweetsRequestDecorator < ApplicationDecorator
  delegate_all

  def message
    text = I18n.t('delete_tweets.message.destroy_count', count: object.destroy_count)

    if object.error_class.blank?
      if object.finished?
        text += I18n.t('delete_tweets.message.finished')
      else
        text += I18n.t('delete_tweets.message.processing')
      end
    else
      text += I18n.t('delete_tweets.message.failed')
    end

    text.html_safe
  end

  def time
    updated = object.updated_at.in_time_zone('Tokyo')
    if updated.today?
      I18n.l(updated, format: :delete_tweets_short)
    else
      I18n.l(updated, format: :delete_tweets_long)
    end
  end
end
