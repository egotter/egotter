module Api
  module V1
    class CreatePeriodicTweetRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :value_must_be_true_or_false

      def update
        if params['value'] == 'true'
          if create_record(current_user)
            render json: {message: t('.update.success_on_html')}
          else
            render json: {message: t('.update.fail')}, status: :bad_request
          end
        elsif params['value'] == 'false'
          if destroy_record(current_user)
            render json: {message: t('.update.success_off_html')}
          else
            render json: {message: t('.update.fail')}, status: :bad_request
          end
        end
      end

      private

      def value_must_be_true_or_false
        if !params.has_key?('value') || !%w(true false).include?(params['value'])
          render json: {message: t('.update.fail')}, status: :bad_request
        end
      end

      def create_record(user)
        !CreatePeriodicTweetRequest.exists?(user_id: user.id) && CreatePeriodicTweetRequest.create(user_id: user.id)
      end

      def destroy_record(user)
        (request = CreatePeriodicTweetRequest.find_by(user_id: user.id)) && request.destroy
      end
    end
  end
end
