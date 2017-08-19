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

  def friends_stat
    twitter_user = TwitterUser.latest(uid)
    friend_uids = twitter_user.friendships.pluck(:friend_uid)
    follower_uids = twitter_user.followerships.pluck(:follower_uid)
    mutual_friend_uids = twitter_user.mutual_friendships.pluck(:friend_uid)

    {
      friends_count:             friend_uids.size,
      followers_count:           follower_uids.size,
      one_sided_friends_count:   twitter_user.one_sided_friendships.size,
      one_sided_followers_count: twitter_user.one_sided_followerships.size,
      mutual_friends_count:      mutual_friend_uids.size,
      one_sided_friends_rate:    twitter_user.one_sided_friends_rate,
      one_sided_followers_rate:  twitter_user.one_sided_followers_rate,
      follow_back_rate:          twitter_user.follow_back_rate,
      followed_back_rate:        mutual_friend_uids.size.to_f / friend_uids.size,
      mutual_friends_rate:       mutual_friend_uids.size.to_f / (friend_uids | follower_uids).size
    }
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{uid}"
    Hash.new(0)
  end

  def tweets_stat
    twitter_user = TwitterUser.latest(uid)
    tweets = twitter_user.statuses
    tweet_days = tweets.map(&:tweeted_at).map { |time| "#{time.year}/#{time.month}/#{time.day}" }
    tweets_interval =
      if tweets.any?
        (tweets.first.tweeted_at.to_i - tweets.last.tweeted_at.to_i).to_f / tweets.size / 60
      else
        0.0
      end

    {
      statuses_count:         twitter_user.statuses_count,
      statuses_per_day_count: (tweets.size / tweet_days.uniq.size rescue 0.0),
      twitter_days:           (Date.today - twitter_user.account_created_at.to_date).to_i,
      most_active_hour:       most_active_hour,
      most_active_wday:       most_active_wday,
      tweets_interval:        tweets_interval.round(1),
      mentions_count:         tweets.reject(&:retweet?).select(&:mentions?).size,
      media_count:            tweets.reject(&:retweet?).select(&:media?).size,
      links_count:            tweets.reject(&:retweet?).select(&:urls?).size,
      hashtags_count:         tweets.reject(&:retweet?).select(&:hashtags?).size,
      locations_count:        tweets.reject(&:retweet?).select(&:location?).size,
      wday:                   wday,
      wday_drilldown:         wday_drilldown,
      hour:                   hour,
      hour_drilldown:         hour_drilldown,
      breakdown:              breakdown
    }
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{uid}"
    Hash.new(0)
  end

  def most_active_hour
    max_value = hour.map { |obj| obj[:y] }.max
    hour.find { |obj| obj[:y] == max_value }.try(:fetch, :name, nil)
  end

  def most_active_wday
    max_value = wday.map { |obj| obj[:y] }.max
    wday.find { |obj| obj[:y] == max_value }.try(:fetch, :name, nil)
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
