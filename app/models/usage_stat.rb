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
#  tweet_clusters_json :text(65535)      not null
#
# Indexes
#
#  index_usage_stats_on_uid  (uid) UNIQUE
#

class UsageStat < ActiveRecord::Base
  %i(wday wday_drilldown hour hour_drilldown usage_time breakdown hashtags mentions tweet_clusters).each do |name|
    define_method(name) do
      ivar_name = "@#{name}_cache"
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      else
        str = send("#{name}_json")
        if str.present?
          instance_variable_set(ivar_name, JSON.parse(str, symbolize_names: true))
        else
          nil
        end
      end
    end
  end

  def mention_uids
    mentions.keys.map(&:to_s).map(&:to_i)
  end

  def self.builder(uid)
    Builder.new(uid)
  end

  class Builder
    attr_reader :uid

    def initialize(uid)
      @uid = uid.to_i
    end

    def build
      stat = UsageStat.find_or_initialize_by(uid: uid)
      wday, wday_drilldown, hour, hour_drilldown, usage_time = calc(@statuses)

      stat.assign_attributes(
        wday_json:           wday.to_json,
        wday_drilldown_json: wday_drilldown.to_json,
        hour_json:           hour.to_json,
        hour_drilldown_json: hour_drilldown.to_json,
        usage_time_json:     usage_time.to_json,
        breakdown_json:      extract_breakdown(@statuses).to_json,
        hashtags_json:       extract_hashtags(@statuses).to_json,
        mentions_json:       extract_mentions(@statuses).to_json,
        tweet_clusters_json: ApiClient.dummy_instance.tweet_clusters(@statuses, limit: 100).to_json
      )
      stat
    end

    def statuses(statuses)
      @statuses = statuses
      self
    end

    private

    def calc(statuses)
      return [{}, {}, {}, {}, {}] if statuses.empty?
      one_year_ago = 365.days.ago
      times = statuses.map(&:tweeted_at).select { |time| time > one_year_ago  }
      ApiClient.dummy_instance.usage_stats(times, day_names: I18n.t('date.abbr_day_names'))
    end

    def extract_breakdown(statuses)
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

    def extract_hashtags(statuses)
      statuses.reject(&:retweet?).select(&:hashtags?).map(&:hashtags).flatten.
        map { |h| "##{h}" }.each_with_object(Hash.new(0)) { |hashtag, memo| memo[hashtag] += 1 }.
        sort_by { |h, c| [-c, -h.size] }.to_h
    end

    def extract_mentions(statuses)
      statuses.reject(&:retweet?).select(&:mentions?).map(&:mention_uids).flatten.
        each_with_object(Hash.new(0)) { |uid, memo| memo[uid.to_s.to_sym] += 1 }.
        sort_by { |u, c| -c }.to_h
    end
  end
end
