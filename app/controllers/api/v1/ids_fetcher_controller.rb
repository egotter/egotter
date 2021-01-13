module Api
  module V1
    class IdsFetcherController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :require_uid
      before_action :require_key

      def create
        uid = params[:uid].to_i
        cursor = params[:cursor] || -1

        cache = IdsFetcherCache.new(worker_class)
        if (data = cache.read(uid, cursor))
          render json: {ids: data['ids'], next_cursor: data['next_cursor']}
        else
          jid = worker_class.perform_async(uid, cursor)
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
