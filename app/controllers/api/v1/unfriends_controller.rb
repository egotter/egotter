module Api
  module V1
    class UnfriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        user = @twitter_user.twitter_db_user
        uids = user.unfriendships.limit(limit).pluck(:friend_uid)
        size = user.unfriendships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit: 10)
        friendships = @twitter_user.twitter_db_user.unfriendships.where("sequence >= ?", min_sequence).limit(limit)
        if friendships.empty?
          [[], -1]
        else
          [friendships.map(&:friend_uid), friendships.last.sequence]
        end
      end
    end
  end
end