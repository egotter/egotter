module Api
  module V1
    class Base < ApplicationController

      before_action :reject_spam_access!

      include ApiRequestConcern
      include UsersHelper
      include ApiLimitationHelper

      SUMMARY_LIMIT = 20

      def summary
        uids, size = summary_uids
        update_twitter_db_users(uids)

        users = TwitterDB::User.where_and_order_by_field(uids: uids)

        if remove_related_page? && uids.any? && uids.size != users.size
          users = users.index_by(&:uid)
          users = uids.map { |uid| users[uid] }.compact
        end

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

        candidate_uids = paginator.users.map(&:uid)
        users = TwitterDB::User.where_and_order_by_field(uids: candidate_uids)

        if remove_related_page? && candidate_uids.any? && candidate_uids.size != users.size
          users = users.index_by(&:uid)
          users = candidate_uids.map { |uid| users[uid] }.compact
        end

        update_twitter_db_users(candidate_uids)

        options = {}
        options[:suspended_uids] = collect_suspended_uids(request_context_client, paginator.users.map(&:uid)) if remove_related_page?
        options[:blocking_uids] = current_user_blocking_uids if remove_related_page?
        options[:friend_uids] = current_user_friend_uids if unfriend_related_page?
        options[:follower_uids] = current_user_follower_uids if unfollower_related_page?

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

        follower_uids = vc.current_user_follower_uids

        users.map.with_index do |user, i|
          user = TwitterUserDecorator.new(user, context: options)
          {
              screen_name: user.screen_name,
              profile_image_url: user.censored_profile_icon_url('bigger'),
              name_with_icon: user.name_with_icon,
              status_labels: user.status_labels,
              followed_label: follower_uids.include?(user.uid) ? user.single_followed_label : nil,
              description: vc.linkify(user.censored_description),
              statuses_count: user.delimited_statuses_count,
              friends_count: user.delimited_friends_count,
              followers_count: user.delimited_followers_count,
              timeline_url: timeline_path(user, via: via),
              status_url: status_path(user, via: via),
              friend_url: friend_path(user, via: via),
              follower_url: follower_path(user, via: via),
              index: max_sequence + i,
          }
        end
      end

      def unfriend_related_page?
        %w(unfriends mutual_unfriends blockers).include?(controller_name)
      end

      def unfollower_related_page?
        %w(unfollowers mutual_unfriends blockers).include?(controller_name)
      end

      def remove_related_page?
        %w(unfriends unfollowers mutual_unfriends blockers).include?(controller_name)
      end

      def request_context_client
        @request_context_client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
      end

      def collect_suspended_uids(client, uids)
        users = client.users(uids).select { |user| !user[:suspended] }
        uids - users.map { |u| u[:id] }
      rescue => e
        TwitterApiStatus.no_user_matches?(e) ? uids : []
      end

      def update_twitter_db_users(uids)
        if user_signed_in? && uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
          TwitterDBUsersUpdatedFlag.on(uids)
          CreateTwitterDBUserWorker.perform_async(uids, user_id: current_user.id, enqueued_by: current_via)
        end
      end
    end
  end
end
