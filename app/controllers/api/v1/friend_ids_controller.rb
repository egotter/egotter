module Api
  module V1
    class FriendIdsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :require_uid
      before_action :require_key

      def create
        cache = FetchFriendIdsWorker::Cache.new
        if (uids = cache.read(params[:uid].to_i))
          render json: {uids: uids}
        else
          jid = FetchFriendIdsWorker.perform_async(params[:uid].to_i)
          message = jid ? 'Start fetching' : 'Already running'
          render json: {message: message}, status: :accepted
        end
      end

      private

      def require_uid
        unless params[:uid]&.match?(Validations::UidValidator::REGEXP)
          render json: {message: 'Invalid uid'}, status: :bad_request
        end
      end

      def require_key
        unless params[:key] && ENV['ALLY_SOCIAL_KEY'] && params[:key] == ENV['ALLY_SOCIAL_KEY']
          render json: {message: 'Invalid key'}, status: :bad_request
        end
      end
    end
  end
end
