module Api
  module V1
    class Base < ApplicationController

      layout false

      # before_action -> { head :bad_request }, unless: -> { params[:token] }
      # skip_before_action :verify_authenticity_token

      before_action -> { valid_uid?(params[:uid]) }
      before_action -> { twitter_user_persisted?(params[:uid]) }
      before_action -> { twitter_db_user_persisted?(params[:uid]) }
      before_action -> { @twitter_user = TwitterUser.latest_by(uid: params[:uid]) }
      before_action -> { !protected_search?(@twitter_user) }

      def summary
        uids, size = summary_uids

        unless from_crawler?
          CreateTwitterDBUserWorker.perform_async(uids, user_id: current_user_id, enqueued_by: 'Api::V1::Base summary')
        end

        # This method makes the users unique.
        users = TwitterDB::User.where_and_order_by_field(uids: uids)

        users = users.map { |user| Hashie::Mash.new(to_summary_hash(user)) }
        chart = [{name: t("charts.#{controller_name}"), y: 100.0 / 3.0}, {name: t('charts.others'), y: 200.0 / 3.0}]

        render json: {name: controller_name, count: size, users: users, chart: chart}
      end

      def list
        paginator = Paginator.new(list_users).
            max_sequence(params[:max_sequence]).
            limit(params[:limit]).
            sort_order(params[:sort_order]).
            filter(params[:filter]).
            paginate

        decorator = Decorator.new(paginator.users).
            user_id(current_user_id).
            controller_name(controller_name).
            decorate

        users = decorator.users.map { |user| Hashie::Mash.new(user) }

        response_json = {name: controller_name, max_sequence: paginator.max_sequence, limit: paginator.limit}

        if params[:html]
          grid_class = ['col-xs-12', 'col-xs-12 col-sm-6'].include?(params[:grid_class]) ? params[:grid_class] : 'col-xs-12'
          insert_ad = !(params[:insert_ad] == 'false')
          html = render_to_string partial: 'twitter/user', collection: users, cached: true, locals: {grid_class: grid_class, ad: insert_ad}, formats: %i(html)
          response_json[:users] = html
        else
          response_json[:users] = users
        end

        render json: response_json
      end

      private

      def to_summary_hash(user)
        {
            uid: user.uid.to_s,
            screen_name: user.screen_name,
            profile_image_url_https: user.profile_image_url_https.to_s
        }
      end
    end
  end
end