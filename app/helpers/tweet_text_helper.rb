module TweetTextHelper
  def short_url
    Util::UrlShortener.shorten(request.original_url)
  end

  def error_text
    t('tweet_text.something_is_wrong', kaomoji: Kaomoji.happy, url: 'http://egotter.com')
  end

  def clusters_belong_to_text(clusters, tu)
    t('tweet_text.clusters_belong_to',
      user: tu.mention_name,
      clusters: "#{clusters.join(t('dictionary.delim'))}",
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{clusters.inspect} #{tu.inspect}"
    error_text
  end

  # stats = [
  #   {:name=>"Sun", :y=>14.778310502283107},
  #   ...
  #   {:name=>"Sat", :y=>12.115753424657534}
  # ]
  def usage_time_text(stats, tu)
    return error_text if stats.nil?

    total_minutes = stats.map { |obj| obj[:y] }.sum { |y| y.nil? ? 0 : y }
    minutes_per_day = total_minutes / stats.map { |obj| obj[:y] }.count { |y| !y.nil? }
    minutes_per_week = minutes_per_day * 7

    tweets_days = tu.statuses.map { |t| t.tweeted_at.to_date.to_s(:long) }.uniq.size
    hour_count = tu.statuses.each_with_object(Hash.new(0)) { |s, memo| memo[s.tweeted_at.hour] += 1 }
    tweets_per_hour = hour_count.values.sum.to_f / tweets_days / 24
    level =
      case tweets_per_hour
        when 0..2 then t('searches.usage_stats.usage_level.first')
        when 2..3 then t('searches.usage_stats.usage_level.second')
        when 3..5 then t('searches.usage_stats.usage_level.third')
        when 5..10 then t('searches.usage_stats.usage_level.fourth')
        when 10..100 then t('searches.usage_stats.usage_level.fifth')
      end

    avg, total =
      [minutes_per_day, minutes_per_week].map do |miutes|
        if miutes > 120
          t('datetime.distance_in_words.about_x_hours.other', count: (minutes / 120).round(1))
        else
          t('datetime.distance_in_words.x_minutes.other', count: miutes.round)
        end
      end

    t('searches.usage_stats.usage_time', user: tu.mention_name, total: total, avg: avg, level: level, url: usage_stats_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{stats.inspect} #{tu.inspect}"
    error_text
  end

  # wday_stats = [
  #   {:name=>"Sun", :y=>111, :drilldown=>"Sun"},
  #   ...
  #   {:name=>"Sat", :y=>90,  :drilldown=>"Sat"}
  # ]
  # hour_stats = [
  #   {:name=>"0", :y=>66, :drilldown=>"0"},
  #   ...
  #   {:name=>"23", :y=>87, :drilldown=>"23"}
  # ]
  def usage_per_xxx_text(wday_stats, hour_stats, tu)
    wday_max_y = wday_stats.map { |obj| obj[:y] }.max
    wday = wday_stats.find { |obj| obj[:y] == wday_max_y }[:name]
    hour_max_y = hour_stats.map { |obj| obj[:y] }.max
    hour = hour_stats.find { |obj| obj[:y] == hour_max_y }[:name]
    t('searches.usage_stats.usage_per_xxx', user: tu.mention_name, wday: wday, hour: hour, url: usage_stats_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{wday_stats.inspect} #{hour_stats.inspect} #{tu.inspect}"
    logger.warn e.backtrace.join("\n")
    error_text
  end

  def usage_kind_text(kind, tu)
    t('searches.usage_stats.usage_kind', user: tu.mention_name, mention: kind[:mentions].round, image: kind[:media].round, link: kind[:urls].round, hashtag: kind[:hashtags].round, location: kind[:location].round, url: usage_stats_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{kind.inspect} #{tu.inspect}"
    error_text
  end

  def usage_hashtags_text(hashtags, tu)
    hashtags = hashtags.to_a.map { |obj| obj[:name] }.slice(0, 5).join(' ')
    t('searches.usage_stats.usage_hashtags', user: tu.mention_name, hashtags: hashtags, url: usage_stats_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{hashtags.inspect} #{tu.inspect}"
    error_text
  end

  def close_friends_text(users, tu)
    t('tweet_text.close_friends', user: tu.mention_name, users: users.slice(0, 5).map { |u| "@#{u.screen_name}" }.join("\n"), url: close_friends_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{users.inspect} #{tu.inspect}"
    error_text
  end

  def inactive_friends_text(users, tu)
    users = ".#{users.map { |u| "@#{u.screen_name}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
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
      screen_name: "#{tu.mention_name}#{t('dictionary.honorific')}",
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
    users = "#{users.map { |u| "@#{u.screen_name}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    users += "#{t('dictionary.delim')}#{t('tweet_text.others', num: others_num)}" if others_num > 0
    t('tweet_text.common_friends',
      users: users,
      user: "#{tu.mention_name}#{t('dictionary.honorific')}",
      login: "#{current_user.mention_name}#{t('dictionary.honorific')}",
      kaomoji: Kaomoji.happy,
      url: short_url)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{users.inspect} #{tu.inspect}"
    error_text
  end

  def common_followers_text(users, tu, others_num = 0)
    users = "#{users.map { |u| "@#{u.screen_name}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}"
    users += "#{t('dictionary.delim')}#{t('tweet_text.others', num: others_num)}" if others_num > 0
    t('tweet_text.common_friends',
      users: users,
      user: "#{tu.mention_name}#{t('dictionary.honorific')}",
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
