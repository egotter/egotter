module Api
  module V1
    class ShareTweetsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :require_text!

      def create
        text = params[:text]
        text += " #{TweetRequest.share_suffix(current_user)}" unless text.include?('http')
        validator = TweetRequest::TextValidator.new(text)

        unless validator.valid?
          render json: {message: t('.fail')}, status: :bad_request
          return
        end

        via = params[:via]&.truncate(100)
        request = TweetRequest.create!(user_id: current_user.id, text: text)

        unless CreateTweetWorker.perform_async(request.id, requested_by: via)
          request.update(deleted_at: Time.zone.now)
          render json: {message: t('.fail')}, status: :bad_request
          return
        end

        SendCreateTweetStartedWorker.perform_async(request.id, via: via)
        render json: {message: t('.success_html', user: current_user.screen_name)}
      rescue => e
        Airbag.warn "#{controller_name}##{action_name} #{e.inspect} user_id=#{current_user.id}"
        render json: {message: t('.fail')}, status: :bad_request
      end

      def require_text!
        if params[:text].blank?
          head :bad_request
        end
      end
    end
  end
end
