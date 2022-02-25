module Api
  module V1
    class DeleteTweetsNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        if DeleteTweetsByArchiveRequest.where(user_id: current_user.id, archive_name: validated_archive).where.not(started_at: nil).exists?
          head :bad_request
        else
          request = DeleteTweetsByArchiveRequest.create(user_id: current_user.id, archive_name: validated_archive, since_date: validated_since, until_date: validated_until)
          CreateDeleteTweetsUploadCompletedMessageWorker.perform_async(current_user.id, since: request.since_date, until: request.until_date)
          SendMessageToSlackWorker.perform_async(:monit_delete_tweets, "`Upload completed` user_id=#{current_user.id} request_id=#{request.id}")
          render json: {status: 'ok'}
        end
      end

      private

      def validated_archive
        if params[:filename]&.match?(S3::ArchiveData::FILENAME_REGEXP)
          params[:filename]
        end
      end

      DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/

      def validated_since
        if params[:since]&.match?(DATE_REGEXP)
          "#{params[:since]} 00:00:00 JST"
        end
      end

      def validated_until
        if params[:until]&.match?(DATE_REGEXP)
          "#{params[:until]} 00:00:00 JST"
        end
      end
    end
  end
end
