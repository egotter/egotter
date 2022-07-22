module Api
  module V1
    class BlockersController < ::Api::BaseController
      include BlockersConcern

      before_action :authenticate_user!
      before_action :search_yourself!
      before_action :has_subscription!

      private

      def summary_uids(limit: Order::FREE_PLAN_BLOCKERS_LIMIT)
        uids = @twitter_user.blocker_uids
        [uids.take(limit), uids.size]
      end

      def list_uids
        @twitter_user.blocker_uids
      end
    end
  end
end
