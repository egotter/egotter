class DeleteTweetsRequestDecorator < ApplicationDecorator
  delegate_all

  def message
    if object.error_class.blank?
      if object.finished?
        text = I18n.t('delete_tweets.message.finished', count: object.destroy_count)
      else
        text = I18n.t('delete_tweets.message.processing_html', count: object.destroy_count)
      end
    else
      text = I18n.t('delete_tweets.message.failed_html', count: object.destroy_count)
    end

    text.html_safe
  end

  def time
    if object.updated_at.today?
      if object.updated_at < 1.hour.ago
        I18n.l(object.updated_at.in_time_zone('Tokyo'), format: :delete_tweets_short)
      else
        h.time_ago_in_words_ja(object.updated_at)
      end
    else
      I18n.l(object.updated_at.in_time_zone('Tokyo'), format: :delete_tweets_long)
    end
  end
end
