module Api
  module V1
    class NewFollowersCountPointsController < ApplicationController
      include FriendsCountPointsConcern

      def index
        records = NewFollowersCountPoint.group_by_day(params[:uid], validated_limit)
        data = convert_to_chart_format(records, params[:type])
        render json: {data: data, message: chart_message(params[:uid], records)}
      end

      private

      def chart_message(uid, records)
        user = TwitterDB::User.find_by(uid: uid)

        if records.empty?
          return t('.index.default_message', user: user&.screen_name)
        end

        options = {
            user: user&.screen_name,
            since_date: records[0].date,
            until_date: records[-1].date,
            count: records.map(&:val).map(&:to_i).sum,
        }
        t('.index.message', options)
      rescue => e
        t('.index.default_message', user: user&.screen_name)
      end
    end
  end
end
