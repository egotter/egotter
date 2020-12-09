module Api
  module V1
    class CloseFriendsOgImagesController < ApplicationController

      before_action :must_specify_valid_uid!

      def show
        if (image = CloseFriendsOgImage.find_by(uid: params[:uid])) && image.image.attached?
          render json: {key: image.image.blob.key}
        else
          CreateCloseFriendsOgImageWorker.perform_async(params[:uid])
          head :not_found
        end
      end
    end
  end
end
