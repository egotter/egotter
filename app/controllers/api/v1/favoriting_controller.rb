module Api
  module V1
    class FavoritingController < ::Api::Base

      private

      def summary_uids
        @twitter_user.favorite_friend_uids
      end
    end
  end
end