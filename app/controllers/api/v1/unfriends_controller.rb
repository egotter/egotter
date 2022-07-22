module Api
  module V1
    class UnfriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        resources = @twitter_user.unfriendships
        [resources.limit(limit).pluck(:friend_uid), resources.size]
      end

      def list_users
        # @twitter_user.unfriends(limit: api_list_users_limit)
        uids = @twitter_user.unfriend_uids.take(api_list_users_limit)
        users = TwitterDB::User.where_and_order_by_field(uids: uids)
        users = users.index_by(&:uid)
        uids.map { |uid| users[uid] }.compact
      end

      def list_uids
        @twitter_user.unfriend_uids
      end
    end
  end
end