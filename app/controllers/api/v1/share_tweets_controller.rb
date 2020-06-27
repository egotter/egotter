module Api
  module V1
    class ShareTweetsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        validator = TweetRequest::TextValidator.new("#{params[:text]} #{TweetRequest.share_suffix}")

        if validator.valid?
          request = TweetRequest.new(user_id: current_user.id, text: "#{params[:text]}")
          request.save!
          CreateTweetWorker.perform_async(request.id, requested_by: params[:via])
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
