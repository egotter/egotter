module Api
  module V1
    class DeletableTweetsController < ApplicationController
      include TwitterHelper

      before_action :reject_crawler
      before_action :require_login!
      before_action :user_must_have_tweets, only: :index

      rescue_from StandardError do |e|
        Airbag.exception e, request_details
        render json: {message: t('.index.internal_server_error')}, status: :internal_server_error
      end

      def index
        records = DeletableTweetsFilter.filtered_records(params, current_user.uid)
        total = records.size
        limited_records = records.order(tweet_id: :desc).limit(100)
        if limited_records.empty?
          render json: {tweets: [], message: t('.filtered_tweets_not_found_html', count: DeleteTweetsRequest::DESTROY_LIMIT, url: pricing_path(via: current_via))}
        else
          render json: {user: DeletableTweetsUserDecorator.new(current_user).to_json, tweets: DeletableTweetsDecorator.new(limited_records, current_user).to_json, total: total}
        end
      end

      # TODO Remove later
      def destroy
        if destroy_records(current_user, [params[:id]])
          render json: {status: 'ok'}
        else
          render json: {message: t('.failed_html', url: tweet_url(current_user.screen_name, params[:id]))}, status: :not_found
        end
      end

      def bulk_destroy
        if delete_total_tweets?
          ids = DeletableTweetsFilter.filtered_records(params[:filter_params], current_user.uid).pluck(:tweet_id)
        else
          ids = params[:ids].map(&:to_i)
        end

        if ids.any?
          destroy_records(current_user, ids, params[:filter_params])
          render json: {status: 'ok', size: ids.size}
        else
          render json: {message: t('.not_found')}, status: :not_found
        end
      end

      def force_reload
        SyncDeletableTweetsRequest.create!(user_id: current_user.id)
        DeletableTweet.where(uid: current_user.uid).delete_all

        request = CreateDeletableTweetsRequest.create!(user_id: current_user.id)
        CreateDeletableTweetsWorker.perform_async(request.id)

        render json: {message: t('.success_html')}
      end

      private

      def user_must_have_tweets
        query = DeletableTweet.where(uid: current_user.uid)

        unless query.exists?
          message = t('.index.tweets_not_found_html', count: DeleteTweetsRequest::DESTROY_LIMIT, url: pricing_path(via: current_via))
          render json: {message: message, retry: false}, status: :not_found
          return
        end

        if !query.not_deletion_reserved.not_deleted.exists? && !DeletableTweetsFilter.from_hash(params).to_hash[:deleted]
          message = t('.index.not_deleted_tweets_not_found_html', count: DeleteTweetsRequest::DESTROY_LIMIT, url: pricing_path(via: current_via))
          render json: {message: message, retry: false}, status: :not_found
        end
      end

      def destroy_records(user, tweet_ids, filter_params = {})
        DeletableTweet.reserve_deletion(user, tweet_ids)
        filter_hash = DeletableTweetsFilter.from_hash(filter_params).to_hash.merge(delete_total_tweets: params[:delete_total_tweets])

        request = DeleteTweetsBySearchRequest.create!(
            user_id: user.id,
            reservations_count: tweet_ids.size,
            send_dm: params[:send_dm],
            post_tweet: params[:post_tweet],
            filters: filter_hash.delete_if { |_k, v| v.nil? },
            tweet_ids: tweet_ids,
        )

        request.perform
      end

      def delete_total_tweets?
        params[:delete_total_tweets] && params[:filter_params] &&
            params[:delete_total_tweets].to_i == DeletableTweetsFilter.filtered_records(params[:filter_params], current_user.uid).size
      end
    end
  end
end
