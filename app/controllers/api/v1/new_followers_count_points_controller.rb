module Api
  module V1
    class NewFollowersCountPointsController < ApplicationController
      def index
        records = NewFollowersCountPoint.where(uid: params[:uid]).order(created_at: :desc).limit(100).reverse
        data = records.map { |r| [r.created_at.to_i * 1000, r.value] }
        render json: {data: data, message: chart_message(params[:uid], records)}
      end

      private

      def fetch_user(uid)
        TwitterDB::User.find_by(uid: uid)
      end

      def chart_message(uid, records)
        options = {
            user: fetch_user(uid)&.screen_name,
            since_date: format_time(records[0].created_at),
            until_date: format_time(records[-1].created_at),
            count: records.map(&:value).sum,
        }
        t('.index.message', options)
      rescue => e
        t('.index.default_message', fetch_user(uid)&.screen_name)
      end

      def format_time(time)
        time.strftime('%Y-%m-%d')
      end
    end
  end
end
