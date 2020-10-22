module Api
  module V1
    class AccountStatusesController < ApplicationController

      skip_before_action :verify_authenticity_token

      before_action :reject_crawler
      before_action :require_login!
      before_action { valid_screen_name?(params[:screen_name]) }

      def show
        screen_name = params[:screen_name]
        cache = AccountStatus::Cache.new

        if cache.exists?(screen_name)
          if cache.invalid?(screen_name)
            render json: {message: t('.invalid', user: screen_name)}
          elsif cache.not_found?(screen_name)
            render json: {message: t('.not_found', user: screen_name)}
          elsif cache.suspended?(screen_name)
            render json: {message: t('.suspended', user: screen_name)}
          elsif cache.blocked?(screen_name)
            render json: {message: t('.blocked', user: screen_name)}
          elsif cache.error?(screen_name)
            render json: {message: t('.error', user: screen_name)}
          elsif cache.locked?(screen_name)
            render json: {message: t('.locked', user: screen_name)}
          elsif cache.protected?(screen_name)
            render json: {message: t('.protected', user: screen_name)}
          elsif cache.ok?(screen_name)
            case cache.is_follower?(screen_name)
            when true
              message = t('.is_follower', user1: current_user.screen_name, user2: screen_name)
            when false
              message = t('.is_not_follower', user1: current_user.screen_name, user2: screen_name)
            else
              message = nil
            end
            render json: {status: 'ok', message: message}
          else
            render json: {message: t('.error', user: screen_name)}
          end
        else
          CreateAccountStatusWorker.perform_async(screen_name, user_id: current_user.id)
          render json: {status: 'retry'}
        end
      end
    end
  end
end
