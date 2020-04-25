module Api
  module V1
    class SummaryController < ApplicationController
      include Concerns::ApiRequestConcern

      def summary
        render json: {
            one_sided_friends: @twitter_user.one_sided_friendships.size,
            one_sided_followers: @twitter_user.one_sided_followerships.size,
            mutual_friends: @twitter_user.mutual_friendships.size,
            unfriends: @twitter_user.unfriendships.size,
            unfollowers: @twitter_user.unfollowerships.size,
            blocking_or_blocked: @twitter_user.block_friendships.size
        }
      end
    end
  end
end
