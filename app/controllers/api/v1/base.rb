module Api
  module V1
    class Base < ApplicationController
      include ApiRequestConcern
      include AccountStatusesHelper
      include UsersHelper
      include ApiLimitationHelper

      before_action { self.access_log_disabled = true }

      class OnlyForLoginUserError < StandardError; end

      rescue_from OnlyForLoginUserError do |e|
        render json: {name: controller_name, message: t('before_sign_in.only_for_login_user', name: t('timelines.feeds.summary.blockers'))}, status: :forbidden
      end

      SUMMARY_LIMIT = 20

      def summary
        uids, size = summary_uids
        CreateTwitterDBUserWorker.perform_async(uids, user_id: current_user.id, enqueued_by: current_via) if user_signed_in? && uids.any?

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

        candidate_uids = paginator.users.map(&:uid)
        users = TwitterDB::User.where_and_order_by_field(uids: candidate_uids)
        CreateTwitterDBUserWorker.perform_async(candidate_uids, user_id: current_user.id, enqueued_by: current_via) if user_signed_in? && candidate_uids.any?

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
              profile_image_url: vc.bigger_icon_url(user),
              name_with_icon: user.name_with_icon,
              status_labels: user.status_labels,
              followed_label: follower_uids.include?(user.uid) ? user.single_followed_label : nil,
              description: vc.linkify(user.censored_description),
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

      def unfriend_related_page?
        %w(unfriends mutual_unfriends blockers).include?(controller_name)
      end

      def unfollower_related_page?
        %w(unfollowers mutual_unfriends blockers).include?(controller_name)
      end

      def remove_related_page?
        %w(unfriends unfollowers mutual_unfriends blockers).include?(controller_name)
      end
    end
  end
end
