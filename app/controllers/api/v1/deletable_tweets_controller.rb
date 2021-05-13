module Api
  module V1
    class DeletableTweetsController < ApplicationController
      include TwitterHelper

      before_action :reject_crawler
      before_action :require_login!
      before_action :user_must_have_tweets, only: :index

      def index
        query = filter_applied_query(params)
        total = query.size
        records = query.order(tweet_id: :desc).limit(100)
        message = records.empty? ? t('.not_found') : nil
        render json: {user: user_json, tweets: tweets_json(current_user, records), total: total, message: message}
      end

      def destroy
        if destroy_record(current_user, params[:id])
          render json: {status: 'ok'}
        else
          render json: {message: t('.failed_html', url: tweet_url(current_user.screen_name, params[:id]))}, status: :not_found
        end
      end

      def bulk_destroy
        if params[:delete_total_tweets] && params[:filter_params] &&
            params[:delete_total_tweets].to_i == filter_applied_query(params[:filter_params]).size
          ids = filter_applied_query(params[:filter_params]).pluck(:tweet_id)
        else
          ids = params[:ids]
        end
        destroy_records(current_user, ids)
        render json: {status: 'ok', size: ids.size}
      end

      class Filter

        DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/

        def initialize(attrs)
          @retweet_count = attrs[:retweet_count]&.to_i
          @favorite_count = attrs[:favorite_count]&.to_i
          @since_date = Time.zone.parse(attrs[:since_date]) if attrs[:since_date]&.match?(DATE_REGEXP)
          @until_date = Time.zone.parse(attrs[:until_date]) if attrs[:until_date]&.match?(DATE_REGEXP)
          @hashtags = to_bool(attrs[:hashtags])
          @user_mentions = to_bool(attrs[:user_mentions])
          @urls = to_bool(attrs[:urls])
          @media = to_bool(attrs[:media])
          @deleted = to_bool(attrs[:deleted])
        end

        def apply(query)
          if @retweet_count.present?
            query = query.where('retweet_count >= ?', @retweet_count)
          end

          if @favorite_count.present?
            query = query.where('favorite_count >= ?', @favorite_count)
          end

          if @since_date.present?
            query = query.where('tweeted_at >= ?', @since_date)
          end

          if @until_date.present?
            query = query.where('tweeted_at <= ?', @until_date)
          end

          unless @hashtags.nil?
            if @hashtags
              query = query.where('json_length(hashtags) > 0')
            else
              query = query.where('json_length(hashtags) = 0')
            end
          end

          unless @user_mentions.nil?
            if @user_mentions
              query = query.where('json_length(user_mentions) > 0')
            else
              query = query.where('json_length(user_mentions) = 0')
            end
          end

          unless @urls.nil?
            if @urls
              query = query.where('json_length(urls) > 0')
            else
              query = query.where('json_length(urls) = 0')
            end
          end

          unless @media.nil?
            if @media
              query = query.where('json_length(media) > 0')
            else
              query = query.where('json_length(media) = 0')
            end
          end

          if @deleted
            query = query.where.not(deleted_at: nil)
          else
            query = query.where(deleted_at: nil)
          end

          query
        end

        private

        def to_bool(val)
          case val
          when 'true'
            true
          when 'false'
            false
          else
            nil
          end
        end

        class << self
          def from_params(params)
            new(
                retweet_count: params[:retweet_count],
                favorite_count: params[:favorite_count],
                since_date: params[:since_date],
                until_date: params[:until_date],
                hashtags: params[:hashtags],
                user_mentions: params[:user_mentions],
                urls: params[:urls],
                media: params[:media],
                deleted: params[:deleted],
            )
          end
        end
      end

      private

      def user_must_have_tweets
        unless DeletableTweet.where(uid: current_user.uid, deleted_at: nil).exists?
          request = CreateDeletableTweetsRequest.create!(user_id: current_user.id)
          if DeletableTweet.where(uid: current_user.uid).exists?
            CreateDeletableTweetsWorker.perform_in(3.minutes, request.id)
            render json: {message: t('.index.completed_html', count: DeleteTweetsRequest::DESTROY_LIMIT, url: pricing_path(via: current_via)), retry: false}, status: :not_found
          else
            CreateDeletableTweetsWorker.perform_async(request.id)
            render json: {message: t('.index.preparing'), retry: true}, status: :not_found
          end
        end
      end

      def filter_applied_query(params)
        query = DeletableTweet.where(uid: current_user.uid)
        Filter.from_params(params).apply(query)
      end

      def user_json
        user = current_user
        twitter_db_user = TwitterDB::User.find_by(uid: current_user.uid)
        {
            id: user.uid.to_s,
            screen_name: user.screen_name,
            name: twitter_db_user&.name,
            profile_image_url: twitter_db_user&.profile_image_url_https,
        }
      end

      def tweets_json(user, records)
        records.map do |record|
          {
              id: record.tweet_id.to_s,
              text: record.properties['text'],
              retweet_count: record.retweet_count,
              favorite_count: record.favorite_count,
              media: record.media&.map { |m| {url: m['media_url_https']} },
              url: tweet_url(user.screen_name, record.tweet_id),
              created_at: l(record.tweeted_at.in_time_zone('Tokyo'), format: :deletable_tweets_long),
          }
        end
      end

      def destroy_records(user, tweet_ids)
        tweet_ids.each do |tweet_id|
          destroy_record(user, tweet_id)
        end

        request = DeleteTweetsRequest.create(
            user_id: user.id,
            destroy_count: tweet_ids.size,
            send_dm: params[:send_dm],
            tweet: params[:post_tweet],
        )
        request.finished!
        SendDeleteTweetsFinishedWorker.perform_async(request.id)
      end

      def destroy_record(user, tweet_id)
        if (record = DeletableTweet.find_by(uid: user.uid, tweet_id: tweet_id, deleted_at: nil))
          DeleteTweetWorker.perform_async(current_user.id, record.tweet_id)
          record.update(deleted_at: Time.zone.now)
        else
          false
        end
      end
    end
  end
end
