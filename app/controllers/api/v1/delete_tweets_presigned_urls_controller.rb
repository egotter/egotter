module Api
  module V1
    class DeleteTweetsPresignedUrlsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!
      before_action :validate_filename
      before_action :validate_filesize

      def create
        render json: {url: S3::ArchiveData.presigned_url(current_user.uid, params[:filename], params[:filesize])}
      end

      private

      FILENAME_REGEXP = /\Atwitter-20\d{2}-\d{2}-\d{2}-[a-z0-9-]+.zip\z/

      def validate_filename
        unless params[:filename].to_s.match?(FILENAME_REGEXP)
          render json: {message: t('.create.fail')}, status: :bad_request
        end
      end

      def validate_filesize
        if params[:filesize].to_i > 30.gigabytes
          render json: {message: t('.create.fail')}, status: :bad_request
        end
      end
    end
  end
end
