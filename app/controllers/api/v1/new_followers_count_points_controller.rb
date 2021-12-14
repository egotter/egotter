module Api
  module V1
    class NewFollowersCountPointsController < ApplicationController
      include FriendsCountPointsConcern

      def index
        render json: generate_response(NewFollowersCountPoint, params[:uid])
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
