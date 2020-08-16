module Api
  module V1
    class CreatePeriodicTweetRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      before_action do
        if !params.has_key?('value') || !%w(true false).include?(params['value'])
          render json: {message: 'invalid value'}, status: :bad_request
        end
      end

      def update
        if params['value'] == 'true'
          create_record(current_user)
        elsif params['value'] == 'false'
          destroy_record(current_user)
        end
      end

      private

      def create_record(user)
        if (request = CreatePeriodicTweetRequest.find_by(user_id: user.id))
          render json: {message: 'record already created'}, status: :bad_request
        else
          CreatePeriodicTweetRequest.create!(user_id: user.id)
          render json: {message: 'ok(created)'}
        end
      end

      def destroy_record(user)
        if (request = CreatePeriodicTweetRequest.find_by(user_id: user.id))
          request.destroy!
          render json: {message: 'ok(deleted)'}
        else
          render json: {message: 'record not found'}, status: :bad_request
        end
      end
    end
  end
end
