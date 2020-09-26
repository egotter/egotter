module Api
  module V1
    class Base < ApplicationController
      include ApiRequestConcern

      before_action { self.access_log_disabled = true }

      SUMMARY_LIMIT = 20

      def summary
        uids, size = summary_uids

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
            controller_name(controller_name)

        users, options = decorator.decorate
        users = to_list_hash(users, params[:max_sequence].to_i + 1, options)

        render json: {name: controller_name, max_sequence: paginator.max_sequence, limit: paginator.limit, users: users}
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

      def to_list_hash(users, max_sequence, options)
        via = current_via('api_list')
        vc = view_context

        users.map.with_index do |user, i|
          user = TwitterUserDecorator.new(user, context: options)
          {
              screen_name: user.screen_name,
              profile_image_url: vc.bigger_icon_url(user),
              name_with_icon: user.name_with_icon,
              status_labels: user.status_labels,
              followed_label: vc.current_user_follower_uids.include?(user.uid) ? user.single_followed_label : nil,
              description: vc.linkify(user.description),
              statuses_count: user.delimited_statuses_count,
              friends_count: user.delimited_friends_count,
              followers_count: user.delimited_followers_count,
              follow_button: render_to_string(partial: 'twitter/follow_button', locals: {user: user}, formats: [:html]),
              timeline_url: timeline_path(user, via: via),
              status_url: status_path(user, via: via),
              friend_url: friend_path(user, via: via),
              follower_url: follower_path(user, via: via),
              index: max_sequence + i,
          }
        end
      end

      def limit_for_api
        user_signed_in? && current_user.has_valid_subscription? ? Order::BASIC_PLAN_USERS_LIMIT : Order::FREE_PLAN_USERS_LIMIT
      end
    end
  end
end