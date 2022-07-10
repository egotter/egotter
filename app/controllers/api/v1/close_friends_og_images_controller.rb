module Api
  module V1
    class CloseFriendsOgImagesController < ApplicationController

      skip_before_action :reject_spam_ip!, if: -> { request.user_agent.to_s.match?(/\AOgImageProxy/) }

      before_action :valid_uid?

      def show
        if (image = CloseFriendsOgImage.find_by(uid: params[:uid])) && image.image.attached? && image.fresh?
          render json: {key: image.image.blob.key}
        else
          CreateCloseFriendsOgImageWorker.perform_async(params[:uid])
          head :not_found
        end
      end

      private

      def valid_uid?
        unless Validations::UidValidator::REGEXP.match?(params[:uid])
          head :bad_request
        end
      end
    end
  end
end
