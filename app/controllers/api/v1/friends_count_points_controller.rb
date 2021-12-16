module Api
  module V1
    class FriendsCountPointsController < ApplicationController
      include FriendsCountPointsConcern

      def index
        render json: generate_chart_data(FriendsCountPoint, params[:uid])
      end

      private

      def chart_message(uid, records)
        user = TwitterDB::User.find_by(uid: uid)

        if records.empty?
          return t('.index.default_message', user: user&.screen_name)
        end

        options = message_options(records).merge(user: user&.screen_name)
        options[:verb] = options[:increased] ? t('.index.increase') : t('.index.decrease')
        t('.index.message', options)
      rescue => e
        t('.index.default_message', user: user&.screen_name)
      end
    end
  end
end
