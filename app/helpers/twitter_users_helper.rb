module TwitterUsersHelper
  def time_ago_in_words_ja(time)
    diff = Time.zone.now - time
    if diff < 1.minute
      t('datetime.distance_in_words.x_seconds', count: diff.to_i) + t('twitter_users.in_background.before')
    else
      time_ago_in_words(time) + t('twitter_users.in_background.before')
    end
  end
end
