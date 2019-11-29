module TwitterUsersHelper
  def next_creation_message(twitter_user)
    format = (twitter_user.created_at.to_date === Time.zone.now.to_date) ? :next_creation_short : :next_creation_long
    time = I18n.l(twitter_user.created_at.in_time_zone('Tokyo'), format: format)

    if switch_to_request?(twitter_user)
      t('twitter_users.in_background.displayed_data_is_html', time: time)
    else
      t('twitter_users.in_background.next_creation_is_html', time: time, distance_of_time: short_time_ago_in_words(twitter_user))
    end
  end

  def short_time_ago_in_words(twitter_user)
    seconds_diff = twitter_user.next_creation_time - Time.zone.now
    if seconds_diff <= 0
      t('twitter_users.in_background.soon')
    elsif 0 < seconds_diff && seconds_diff < 30
      time_ago_in_words(twitter_user.next_creation_time) # x以内
    else
      t('twitter_users.in_background.go', time: time_ago_in_words(twitter_user.next_creation_time)) # x分後
    end
  end

  def switch_to_request?(twitter_user)
    twitter_user.next_creation_time < Time.zone.now
  end
end
