module ApplicationHelper
  def original_url
    request.original_url
  end

  def close_friends_text(users, tu, url)
    users = ".#{users.map { |u| "@#{u.screen_name}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    if search_oneself?(tu.uid)
      t('tweet_text.close_friends_by_oneself',
        users: users,
        screen_name: "@#{tu.screen_name}",
        kaomoji: Kaomoji.sample,
        url: url)
    elsif search_others?(tu.uid)
      t('tweet_text.close_friends_by_others',
        users: users,
        screen_name: "@#{tu.screen_name}#{t('dictionary.honorific')}",
        kaomoji: Kaomoji.sample,
        me: "@#{current_user.screen_name}",
        url: url)
    elsif !user_signed_in?
      t('tweet_text.close_friends_without_sign_in',
        users: users,
        screen_name: "@#{tu.screen_name}#{t('dictionary.honorific')}",
        kaomoji: Kaomoji.sample,
        url: url)
    else
      t('tweet_text.something_is_wrong', kaomoji: Kaomoji.sample)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect} #{url}"
    t('tweet_text.something_is_wrong', kaomoji: Kaomoji.sample)
  end

  def mutual_friends_text(tu, url)
    rates = tu.mutual_friends_rate
    t('tweet_text.mutual_friends',
      screen_name: "@#{tu.screen_name}#{t('dictionary.honorific')}",
      mutual_friends_rate: rates[0].round,
      one_sided_following_rate: rates[1].round,
      one_sided_followers_rate: rates[2].round,
      kaomoji: Kaomoji.sample,
      url: url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect} #{url}"
    t('tweet_text.something_is_wrong', kaomoji: Kaomoji.sample)
  end
end
