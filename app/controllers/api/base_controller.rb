module Api
  class BaseController < ApplicationController

    before_action :reject_spam_access!

    include ApiRequestConcern
    include UsersHelper
    include ApiLimitationHelper

    SUMMARY_LIMIT = 20

    def summary
      uids, size = summary_uids

      if user_signed_in?
        CreateTwitterDBUserWorker.perform_async(uids, user_id: current_user.id, enqueued_by: current_via)
      end

      users = TwitterDB::User.order_by_field(uids).where(uid: uids)

      if remove_related_page? && uids.any? && uids.size != users.size
        users = users.index_by(&:uid)
        users = uids.map { |uid| users[uid] }.compact
      end

      users = users.map { |user| Hashie::Mash.new(to_summary_hash(user)) }

      render json: {name: controller_name, count: size, users: users}
    end

    def list
      if params[:max_sequence].to_i + 1 >= api_list_users_limit
        render json: {name: controller_name, max_sequence: -1, limit: 0, users: []}
        return
      end

      proxy = TwitterDB::Proxy.new(list_uids).
          slice(10).
          offset(params[:max_sequence]).
          limit([params[:limit].to_i, 10].min).
          sort(params[:sort_order]).
          filter(params[:filter])
      result = proxy.result
      users = result[:users]
      candidate_uids = users.map(&:uid)

      if remove_related_page? && candidate_uids.any? && candidate_uids.size != users.size
        users = users.index_by(&:uid)
        users = candidate_uids.map { |uid| users[uid] }.compact
      end

      if user_signed_in?
        CreateTwitterDBUserWorker.perform_async(candidate_uids, user_id: current_user.id, enqueued_by: current_via)
      end

      options = {}
      options[:suspended_uids] = collect_suspended_uids(request_context_client, users.map(&:uid)) if remove_related_page?
      options[:blocking_uids] = current_user_blocking_uids if remove_related_page?
      options[:friend_uids] = current_user_friend_uids if unfriend_related_page?
      options[:follower_uids] = current_user_follower_uids if unfollower_related_page?

      users = to_list_hash(users, params[:max_sequence].to_i + 1, options)

      render json: {name: controller_name, max_sequence: result[:offset] + users.size - 1, limit: result[:limit], users: users}
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
  end
end
