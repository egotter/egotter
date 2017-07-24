module UsageStatsHelper
  def most_active_wday(count_by_dway)
    count_by_dway.max_by { |obj| obj[:y] }[:name]
  end

  def most_active_hour(count_by_hour)
    count_by_hour.max_by { |obj| obj[:y] }[:name]
  end

  # count_by_wday = [
  #   {:name=>"Sun", :y=>14.778310502283107},
  #   ...
  #   {:name=>"Sat", :y=>12.115753424657534}
  # ]
  def minutes_per_day(count_by_wday)
    minutes = count_by_wday.map { |obj| obj[:y] }.compact.sum
    days = count_by_wday.map { |obj| obj[:y] }.compact.size
    days == 0 ? 0 : minutes / days
  end

  def minutes_per_week(count_by_wday)
    minutes_per_day(count_by_wday) * 7
  end

  def tweets_level(tweets)
    three_days_ago = 3.days.ago
    case tweets.count { |s| s.tweeted_at > three_days_ago } / (24 * 3)
      when 0..2 then 1
      when 2..3 then 2
      when 3..5 then 3
      when 5..10 then 4
      when 10..10000 then 5
      else 1
    end
  end
end
