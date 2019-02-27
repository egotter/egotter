module Api
  module V1
    class FriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.friend_uids.take(limit)
        size = @twitter_user.friend_uids.size
        [uids, size]
      end

      def list_uids(min_sequence, limit:)
        uids = @twitter_user.friend_uids.slice(min_sequence, limit)
        if uids.empty?
          [[], -1]
        else
          [uids, min_sequence + uids.size - 1]
        end
      end

      def list_users
        @twitter_user.friends
      end
    end
  end
end