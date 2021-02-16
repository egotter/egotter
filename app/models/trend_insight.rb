# == Schema Information
#
# Table name: trend_insights
#
#  id          :bigint(8)        not null, primary key
#  trend_id    :bigint(8)        not null
#  words_count :json
#  times_count :json
#  users_count :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_trend_insights_on_created_at  (created_at)
#  index_trend_insights_on_trend_id    (trend_id) UNIQUE
#
class TrendInsight < ApplicationRecord
  belongs_to :trend

  validates :trend_id, presence: true, uniqueness: true

  class << self
    def calc_words_count(tweets)
      text = tweets.take(10000).map(&:text).join(' ')
      WordCloud.new.count_words(text).sort_by { |_, v| -v }
    end

    def calc_times_count(tweets)
      times = tweets.map(&:tweeted_at)

      times_count = times.each_with_object(Hash.new(0)) do |t, memo|
        time = Time.new(t.year, t.month, t.day, t.hour, t.min, 0, '+00:00')
        memo[time.to_i] += 1
      end

      times_count.sort_by { |k, _| k }.map do |timestamp, count|
        [timestamp, count]
      end
    end

    def calc_users_count(tweets)
      values = tweets.map(&:uid)

      values_count = values.each_with_object(Hash.new(0)) do |value, memo|
        memo[value] += 1
      end

      values_count.sort_by { |_, v| -v }.map do |value, count|
        [value, count]
      end
    end
  end

  def update_words_count(tweets)
    result = self.class.calc_words_count(tweets)
    update(words_count: result)
  end

  def update_times_count(tweets)
    result = self.class.calc_times_count(tweets)
    update(times_count: result)
  end

  def update_users_count(tweets)
    result = self.class.calc_users_count(tweets)
    update(users_count: result)
  end
end
