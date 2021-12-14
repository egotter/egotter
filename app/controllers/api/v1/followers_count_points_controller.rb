module Api
  module V1
    class FollowersCountPointsController < ApplicationController
      include FriendsCountPointsConcern

      def index
        records = FollowersCountPoint.group_by_day(params[:uid], validated_limit)
        data = convert_to_chart_format(records, params[:type])
        render json: {data: data, message: chart_message(params[:uid], records)}
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
