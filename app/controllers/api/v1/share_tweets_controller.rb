module Api
  module V1
    class ShareTweetsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        validator = TweetRequest::TextValidator.new("#{params[:text]} #{TweetRequest.share_suffix}")

        if validator.valid?
          via = params[:via]&.truncate(100)
          request = TweetRequest.create!(user_id: current_user.id, text: "#{params[:text]}")
          CreateTweetWorker.perform_async(request.id, requested_by: via)
          SendCreateTweetStartedWorker.perform_async(request.id, via: via)
          render json: {count: current_user.sharing_count}
        else
          head :bad_request
        end

      rescue => e
        logger.warn "#{controller_name}##{action_name} #{e.inspect} user_id=#{current_user.id}"
        head :bad_request
      end
    end
  end
end
