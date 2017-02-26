module TweetTextHelper
  def short_url
    Util::UrlShortener.shorten(request.original_url)
  end

  def error_text
    t('tweet_text.something_is_wrong', kaomoji: Kaomoji.happy, url: 'http://egotter.com')
  end

  def close_friends_text(users, tu)
    t('tweet_text.close_friends', user: mention_name(tu.screen_name), users: users.slice(0, 5).map { |u| mention_name(u.screen_name) }.join("\n"), url: close_friends_search_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{users.inspect} #{tu.inspect}"
    error_text
  end

  def inactive_friends_text(users, tu)
    users = ".#{users.map { |u| "#{mention_name(u.screen_name)}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    t('tweet_text.inactive_friends',
      users: users,
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect}"
    error_text
  end

  def mutual_friends_text(tu)
    rates = tu.mutual_friends_rate
    t('tweet_text.mutual_friends',
      screen_name: "#{mention_name(tu.screen_name)}#{t('dictionary.honorific')}",
      mutual_friends_rate: rates[0].round,
      one_sided_friends_rate: rates[1].round,
      one_sided_followers_rate: rates[2].round,
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{tu.inspect}"
    error_text
  end

  def common_friends_text(users, tu, others_num = 0)
    users = "#{users.map { |u| "#{mention_name(u.screen_name)}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    users += "#{t('dictionary.delim')}#{t('tweet_text.others', num: others_num)}" if others_num > 0
    t('tweet_text.common_friends',
      users: users,
      user: "#{mention_name(tu.screen_name)}#{t('dictionary.honorific')}",
      login: "#{current_user.mention_name}#{t('dictionary.honorific')}",
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect}"
    error_text
  end

  def common_followers_text(users, tu, others_num = 0)
    users = "#{users.map { |u| "#{mention_name(u.screen_name)}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    users += "#{t('dictionary.delim')}#{t('tweet_text.others', num: others_num)}" if others_num > 0
    t('tweet_text.common_friends',
      users: users,
      user: "#{mention_name(tu.screen_name)}#{t('dictionary.honorific')}",
      login: "#{current_user.mention_name}#{t('dictionary.honorific')}",
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect} #{others_num}"
    error_text
  end

  def empty_result_text(title)
    t('tweet_text.empty_result',
      title: title,
      kaomoji: Kaomoji.shirome,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{title.inspect}"
    error_text
  end
end
