# == Schema Information
#
# Table name: audience_insights
#
#  id                     :bigint(8)        not null, primary key
#  uid                    :bigint(8)        not null
#  categories_text        :text(65535)      not null
#  friends_text           :text(65535)      not null
#  followers_text         :text(65535)      not null
#  new_friends_text       :text(65535)      not null
#  new_followers_text     :text(65535)      not null
#  unfriends_text         :text(65535)      not null
#  unfollowers_text       :text(65535)      not null
#  new_unfriends_text     :text(65535)      not null
#  new_unfollowers_text   :text(65535)      not null
#  tweets_categories_text :text(65535)      not null
#  tweets_text            :text(65535)      not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_audience_insights_on_created_at  (created_at)
#  index_audience_insights_on_uid         (uid) UNIQUE
#

class AudienceInsight < ApplicationRecord

  validates :uid, presence: true, uniqueness: true

  before_validation do
    %i(
      unfriends_text
      unfollowers_text
      new_unfriends_text
      new_unfollowers_text
      tweets_categories_text
      tweets_text
    ).each do |key|
      self[key] = '' if self[key].blank?
    end
  end

  # unfriends, unfollowers, new_unfriends, new_unfollowers, tweets_categories and tweets are ignored
  CHART_NAMES = %w(
    categories
    friends
    followers
    new_friends
    new_followers
  )

  CHART_NAMES.each do |chart_name|
    define_method(chart_name) do
      ivar_name = "@#{chart_name}"

      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      else
        text = send("#{chart_name}_text")
        if text.present?
          instance_variable_set(ivar_name, JSON.parse(text, symbolize_names: true))
        else
          nil
        end
      end
    end
  end

  def chart_data(name)
    times = categories.map { |date| Time.zone.parse(date).to_i * 1000 } # milliseconds
    data = []

    case name
    when :friends
      data = friends[:data]
    when :followers
      data = followers[:data]
    when :new_friends
      data = new_friends[:data]
    when :new_followers
      data = new_followers[:data]
    end

    times.zip(data)
  end

  def insufficient_chart_data?
    chart_data(:friends).size <= 1
  end

  def fresh?
    if new_record?
      false
    else
      ttl = Rails.env.production? ? 30.minutes : 1.minutes
      Time.zone.now - updated_at < ttl
    end
  end

  # For debug
  def builder
    Builder.new(uid)
  end

  class Builder
    DEFAULT_TIMEOUT_HANDLER = Proc.new {}

    def initialize(uid, timeout: 10.seconds, concurrency: 1, timeout_handler: DEFAULT_TIMEOUT_HANDLER)
      @uid = uid
      @timeout = timeout
      @concurrency = concurrency
      @timeout_handler = timeout_handler
      @limit = 100
    end

    def build
      chart_builder = nil
      bm('Builder.new') do
        statuses = TwitterUser.latest_by(uid: @uid).status_tweets
        chart_builder = AudienceInsightChartBuilder.new(@uid, statuses: statuses, limit: @limit)
      end

      records = []
      bm('CacheLoader.load') do
        # This code might break the sidekiq process which is processing UpdateAudienceInsightWorker
        records = chart_builder.builder.users
        loader = CacheLoader.new(records, timeout: @timeout, concurrency: @concurrency) do |record|
          record.friend_uids
          record.follower_uids
        end
        loader.load
      rescue CacheLoader::Timeout => e
        @timeout_handler.call(records.size)
        return {}
      end

      attrs = {}
      AudienceInsight::CHART_NAMES.each do |chart_name|
        bm(chart_name) do
          attrs["#{chart_name}_text"] = chart_builder.send(chart_name).to_json
        end
      end

      attrs
    end

    module Instrumentation
      def bm(message, &block)
        start = Time.zone.now
        yield
        @benchmark[message] = Time.zone.now - start
      end

      def build(*args, &blk)
        @benchmark = {}
        start = Time.zone.now

        result = super

        @benchmark['sum'] = @benchmark.values.sum
        @benchmark['elapsed'] = Time.zone.now - start
        Rails.logger.info "Benchmark AudienceInsight::Builder #{@benchmark.inspect}"

        result
      end
    end
    prepend Instrumentation
  end
end
