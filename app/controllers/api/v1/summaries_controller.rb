module Api
  module V1
    class SummariesController < ApplicationController
      include ApiRequestConcern

      def show
        render json: {
            one_sided_friends: @twitter_user.one_sided_friendships.size,
            one_sided_followers: @twitter_user.one_sided_followerships.size,
            mutual_friends: @twitter_user.mutual_friendships.size,
            unfriends: @twitter_user.unfriends_size,
            unfollowers: @twitter_user.unfollowers_size,
            mutual_unfriends: @twitter_user.mutual_unfriendships.size,
        }
      end
    end
  end
end
