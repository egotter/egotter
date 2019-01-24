module Api
  module V1
    class FriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.friendships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit:)
        friendships = @twitter_user.friendships.where("sequence >= ?", min_sequence).limit(limit)
        if friendships.empty?
          [[], -1]
        else
          [friendships.map(&:friend_uid), friendships.last.sequence]
        end
      end

      def list_users
        @twitter_user.friends
      end
    end
  end
end