module TweetTextHelper
  def short_url
    Util::UrlShortener.shorten(request.original_url)
  end

  def error_text
    t('tweet_text.something_is_wrong', kaomoji: Kaomoji.happy, url: 'http://egotter.com')
  end

  def honorific_name(name)
    "#{name}#{t('dictionary.honorific')}"
  end

  def honorific_names(names, delim: t('dictionary.delim'))
    names.map { |name| honorific_name(name) }.join(delim)
  end

  # stats = [
  #   {:name=>"Sun", :y=>14.778310502283107},
  #   ...
  #   {:name=>"Sat", :y=>12.115753424657534}
  # ]
  def usage_time_text(stats, tu)
    return error_text if stats.blank? || stats.all? { |s| s[:y].nil? }

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
      [minutes_per_day, minutes_per_week].map do |minutes|
        if minutes > 120
          t('datetime.distance_in_words.about_x_hours.other', count: (minutes / 120).round(1))
        else
          t('datetime.distance_in_words.x_minutes.other', count: minutes.round)
        end
      end

    t('searches.usage_stats.usage_time', user: tu.mention_name, total: total, avg: avg, level: level, url: usage_stat_url(screen_name: tu.screen_name))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{stats.inspect} #{tu.inspect}"
    error_text
  end
end
