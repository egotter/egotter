module Api
  module V1
    class Base < ApplicationController
      include Concerns::ApiRequestConcern

      before_action { self.access_log_disabled = true }

      SUMMARY_LIMIT = 20

      def summary
        uids, size = summary_uids

        unless from_crawler?
          CreateTwitterDBUserWorker.perform_async(uids, user_id: current_user_id, enqueued_by: 'Api::V1::Base summary')
        end

        # This method makes the users unique.
        users = TwitterDB::User.where_and_order_by_field(uids: uids)
        users = users.map { |user| Hashie::Mash.new(to_summary_hash(user)) }

        render json: {name: controller_name, count: size, users: users}
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
          insert_ad = !(params[:insert_ad] == 'false')
          html = render_to_string partial: 'twitter/user', collection: users, cached: true, locals: {ad: insert_ad}, formats: %i(html)
          response_json[:users_html] = html
        end

        response_json[:users] = users

        render json: response_json
      end

      private

      def to_summary_hash(user)
        {
            uid: user.uid.to_s,
            screen_name: user.screen_name,
            timeline_url: timeline_path(user, via: current_via),
            profile_image_url: user.profile_image_url_https.to_s
        }
      end
    end
  end
end