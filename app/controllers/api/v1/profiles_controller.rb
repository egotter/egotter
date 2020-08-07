module Api
  module V1
    class ProfilesController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action { valid_screen_name?(params[:screen_name]) }

      def show
        user = error = nil
        begin
          user = request_context_client.user(params[:screen_name])
        rescue => e
          error = e
        end

        if AccountStatus.not_found?(error)
          render json: {message: t('.not_found', user: params[:screen_name])}
        elsif AccountStatus.suspended?(error)
          render json: {message: t('.suspended', user: params[:screen_name])}
        elsif error
          render json: {message: t('.error', user: params[:screen_name])}
        elsif user && user[:suspended]
          render json: {message: t('.locked', user: params[:screen_name])}
        else
          render json: {message: t('.ok', user: params[:screen_name]), status: 'ok'}
        end
      end
    end
  end
end
