# == Schema Information
#
# Table name: usage_stats
#
#  id                  :integer          not null, primary key
#  uid                 :integer          not null
#  wday_json           :text(65535)      not null
#  wday_drilldown_json :text(65535)      not null
#  hour_json           :text(65535)      not null
#  hour_drilldown_json :text(65535)      not null
#  usage_time_json     :text(65535)      not null
#  breakdown_json      :text(65535)      not null
#  hashtags_json       :text(65535)      not null
#  mentions_json       :text(65535)      not null
#
# Indexes
#
#  index_usage_stats_on_uid  (uid) UNIQUE
#

class UsageStat < ActiveRecord::Base
  %i(wday wday_drilldown hour hour_drilldown usage_time breakdown hashtags mentions).each do |name|
    define_method(name) do
      var_name = "@#{name}_cache"
      if instance_variable_defined?(var_name)
        instance_variable_get(var_name)
      else
        str = send("#{name}_json")
        if str.present?
          instance_variable_set(var_name, JSON.parse(str, symbolize_names: true))
        else
          nil
        end
      end
    end
  end

  def self.update_by!(uid, statuses)
    stat = find_or_initialize_by(uid: uid)
    wday, wday_drilldown, hour, hour_drilldown, usage_time = calc(statuses)
    stat.update!(
      wday_json:           wday.to_json,
      wday_drilldown_json: wday_drilldown.to_json,
      hour_json:           hour.to_json,
      hour_drilldown_json: hour_drilldown.to_json,
      usage_time_json:     usage_time.to_json,
      breakdown_json:      extract_breakdown(statuses).to_json,
      hashtags_json:       extract_hashtags(statuses).to_json,
      mentions_json:       extract_mentions(statuses).to_json
    )
    stat
  end

  def self.create_by!(*args)
    update_by!(*args)
  end

  private

  def self.calc(statuses)
    return [{}, {}, {}, {}, {}] if statuses.empty?
    one_year_ago = 365.days.ago
    times = statuses.map(&:tweeted_at).select { |time| time > one_year_ago  }
    ApiClient.dummy_instance.usage_stats(times, day_names: I18n.t('date.abbr_day_names'))
  end

  def self.extract_breakdown(statuses)
    tweets = statuses.to_a
    tweets_size = tweets.size
    if tweets_size == 0
      {
        mentions: 0.0,
        media:    0.0,
        urls:     0.0,
        hashtags: 0.0,
        location: 0.0
      }
    else
      {
        mentions: tweets.select(&:mentions?).size.to_f / tweets_size,
        media:    tweets.select(&:media?).size.to_f    / tweets_size,
        urls:     tweets.select(&:urls?).size.to_f     / tweets_size,
        hashtags: tweets.select(&:hashtags?).size.to_f / tweets_size,
        location: tweets.select(&:location?).size.to_f / tweets_size
      }
    end
  end

  def self.extract_hashtags(statuses)
    statuses.select(&:hashtags?).map(&:hashtags).flatten.
      map { |h| "##{h}" }.each_with_object(Hash.new(0)) { |hashtag, memo| memo[hashtag] += 1 }.
      sort_by { |h, c| [-c, -h.size] }.to_h
  end

  def self.extract_mentions(statuses)
    statuses.select(&:mentions?).map(&:mention_uids).flatten.
      each_with_object(Hash.new(0)) { |uid, memo| memo[uid] += 1 }.
      sort_by { |u, c| -c }.to_h
  end
end
