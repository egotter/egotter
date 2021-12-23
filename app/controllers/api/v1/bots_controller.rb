module Api
  module V1
    class BotsController < ApplicationController

      skip_before_action :verify_authenticity_token

      def invalidate_expired_credentials
        Bot.all.each.with_index do |bot, i|
          InvalidateExpiredCredentialWorker.perform_in((0.5 * i).floor, bot.id)
        end
        render json: {status: 'ok'}
      end
    end
  end
end
