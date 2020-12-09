module Api
  module V1
    class ShareTweetsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        text = params[:text]
        text += " #{TweetRequest.share_suffix}" unless text.include?('egotter.com')
        validator = TweetRequest::TextValidator.new(text)

        if validator.valid?
          via = params[:via]&.truncate(100)
          request = TweetRequest.create!(user_id: current_user.id, text: text)
          CreateTweetWorker.perform_async(request.id, requested_by: via)
          SendCreateTweetStartedWorker.perform_async(request.id, via: via)
          render json: {message: t('.success')}
        else
          render json: {message: t('.fail')}, status: :bad_request
        end
      rescue => e
        logger.warn "#{controller_name}##{action_name} #{e.inspect} user_id=#{current_user.id}"
        render json: {message: t('.fail')}, status: :bad_request
      end
    end
  end
end
