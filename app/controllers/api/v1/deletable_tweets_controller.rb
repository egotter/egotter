module Api
  module V1
    class DeletableTweetsController < ApplicationController
      include TwitterHelper

      before_action :reject_crawler
      before_action :require_login!
      before_action :user_must_have_tweets, only: :index

      rescue_from StandardError do |e|
        Airbag.warn "#{e.inspect} controller=#{controller_name} action=#{action_name} user_id=#{current_user&.id}"
        render json: {message: t('.index.internal_server_error')}, status: :internal_server_error
      end

      def index
        query = filter_applied_query(params)
        total = query.size
        records = query.order(tweet_id: :desc).limit(100)
        message = records.empty? ? t('.not_found') : nil
        render json: {user: DeletableTweetsUserDecorator.new(current_user).to_json, tweets: DeletableTweetsDecorator.new(records, current_user).to_json, total: total, message: message}
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
          ids = filter_applied_query(params[:filter_params]).pluck(:tweet_id)
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
        render json: {message: t('.success_html')}
      end

      private

      def user_must_have_tweets
        unless DeletableTweet.not_deletion_reserved.not_deleted.where(uid: current_user.uid).exists?
          request = CreateDeletableTweetsRequest.create!(user_id: current_user.id)
          CreateDeletableTweetsWorker.perform_async(request.id)
          if DeletableTweet.where(uid: current_user.uid).exists?
            message = t('.index.completed_html', count: DeleteTweetsRequest::DESTROY_LIMIT, url: pricing_path(via: current_via))
            render json: {message: message, retry: false}, status: :not_found
          else
            render json: {message: t('.index.preparing'), retry: true}, status: :not_found
          end
        end
      end

      def filter_applied_query(hash)
        query = DeletableTweet.where(uid: current_user.uid)
        DeletableTweetsFilter.from_hash(hash).apply(query)
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
            params[:delete_total_tweets].to_i == filter_applied_query(params[:filter_params]).size
      end
    end
  end
end
