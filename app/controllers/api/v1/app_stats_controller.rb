module Api
  module V1
    class AppStatsController < ApplicationController

      before_action :authenticate_admin!

      def index
        render json: {count: fetch_count(params[:key])}
      end

      private

      def fetch_count(key)
        case key
        when 'sent_users'
          DirectMessageSendLog.sent_messages_count
        when 'received_users'
          DirectMessageReceiveLog.received_sender_ids.size
        when 'sent_messages_total'
          DirectMessageEventLog.total_dm.where('time > ?', 1.day.ago).size
        when 'sent_messages_active'
          DirectMessageEventLog.active_dm.where('time > ?', 1.day.ago).size
        when 'sent_messages_passive'
          DirectMessageEventLog.passive_dm.where('time > ?', 1.day.ago).size
        when 'sent_messages_from_egotter_total'
          DirectMessageEventLog.dm_from_egotter.where('time > ?', 1.day.ago).size
        when 'sent_messages_from_egotter_active'
          DirectMessageEventLog.active_dm_from_egotter.where('time > ?', 1.day.ago).size
        when 'sent_messages_from_egotter_passive'
          DirectMessageEventLog.passive_dm_from_egotter.where('time > ?', 1.day.ago).size
        when 'redis_base_used_memory_rss_human'
          RedisClient.new.info['used_memory_rss_human']
        when 'redis_base_used_memory_peak_human'
          RedisClient.new.info['used_memory_peak_human']
        when 'redis_base_total_system_memory_human'
          RedisClient.new.info['total_system_memory_human']
        when 'redis_in_memory_used_memory_rss_human'
          RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST']).info['used_memory_rss_human']
        when 'redis_in_memory_used_memory_peak_human'
          RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST']).info['used_memory_peak_human']
        when 'redis_in_memory_total_system_memory_human'
          RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST']).info['total_system_memory_human']
        when 'redis_api_cache_used_memory_rss_human'
          ApiClientCacheStore.instance.redis.info['used_memory_rss_human']
        when 'redis_api_cache_used_memory_peak_human'
          ApiClientCacheStore.instance.redis.info['used_memory_peak_human']
        when 'redis_api_cache_total_system_memory_human'
          ApiClientCacheStore.instance.redis.info['total_system_memory_human']
        when 'periodic_reports'
          PeriodicReport.where('created_at > ?', 1.day.ago).size
        when 'periodic_reports_previous_period'
          PeriodicReport.where(created_at: 2.days.ago..1.day.ago).size
        when 'block_reports'
          BlockReport.where('created_at > ?', 1.day.ago).size
        when 'block_reports_previous_period'
          BlockReport.where(created_at: 2.days.ago..1.day.ago).size
        when 'mute_reports'
          MuteReport.where('created_at > ?', 1.day.ago).size
        when 'mute_reports_previous_period'
          MuteReport.where(created_at: 2.days.ago..1.day.ago).size
        when 'search_reports'
          SearchReport.where('created_at > ?', 1.day.ago).size
        when 'search_reports_previous_period'
          SearchReport.where(created_at: 2.days.ago..1.day.ago).size
        when 'user_timeline'
          TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'user_timeline').size
        when 'follow'
          TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'follow!').size
        when 'unfollow'
          TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'unfollow').size
        when 'personality_insight'
          PersonalityInsight.used_count
        else
          nil
        end
      end
    end
  end
end
