module Api
  module V1
    class FriendsCountPointsController < ApplicationController
      def index
        records = FriendsCountPoint.where(uid: params[:uid]).order(created_at: :desc).limit(100).reverse
        data = records.map { |r| [r.created_at.to_i * 1000, r.value] }
        render json: {data: data, message: chart_message(params[:uid], records)}
      end

      private

      def fetch_user(uid)
        TwitterDB::User.find_by(uid: uid)
      end

      def chart_message(uid, records)
        if records.empty?
          return t('.index.default_message', user: fetch_user(uid)&.screen_name)
        end

        options = {
            user: fetch_user(uid)&.screen_name,
            since_date: format_time(records[0].created_at),
            until_date: format_time(records[-1].created_at),
            diff_count: (records[0].value - records[-1].value).abs,
            current_count: records[-1].value,
            verb: records[0].value <= records[-1].value ? t('.index.increase') : t('.index.decrease')
        }
        t('.index.message', options)
      rescue => e
        t('.index.default_message', user: fetch_user(uid)&.screen_name)
      end

      def format_time(time)
        time.strftime('%Y-%m-%d')
      end
    end
  end
end
