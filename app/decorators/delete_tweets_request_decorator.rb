# TODO Remove later
class DeleteTweetsRequestDecorator < ApplicationDecorator
  delegate_all

  def message
    if object.error_class.blank?
      if object.finished?
        I18n.t('delete_tweets.message.finished', count: object.destroy_count)
      else
        I18n.t('delete_tweets.message.processing_html', count: object.destroy_count)
      end
    else
      I18n.t('delete_tweets.message.failed_html', count: object.destroy_count)
    end
  rescue => e
    I18n.t('delete_tweets.message.failed_html', count: object.destroy_count)
  end

  def display_time
    time = object.updated_at

    if time.today?
      if time < 1.hour.ago
        I18n.l(time.in_time_zone('Tokyo'), format: :delete_tweets_short)
      else
        h.time_ago_in_words_ja(time)
      end
    else
      I18n.l(time.in_time_zone('Tokyo'), format: :delete_tweets_long)
    end
  rescue => e
    I18n.l(object.updated_at.in_time_zone('Tokyo'), format: :delete_tweets_long)
  end
end
