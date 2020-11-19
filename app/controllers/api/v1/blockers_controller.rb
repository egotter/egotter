module Api
  module V1
    class BlockersController < ::Api::V1::Base

      private

      def summary_uids(limit: Order::FREE_PLAN_BLOCKERS_LIMIT)
        if current_user_search_for_yourself?(@twitter_user.screen_name)
          uids = @twitter_user.blocker_uids
          [uids.take(limit), uids.size]
        else
          raise OnlyForLoginUserError
        end
      end

      def list_users
        if current_user_search_for_yourself?(@twitter_user.screen_name)
          @twitter_user.blockers(limit: api_list_users_limit)
        else
          TwitterDB::User.none
        end
      end
    end
  end
end
