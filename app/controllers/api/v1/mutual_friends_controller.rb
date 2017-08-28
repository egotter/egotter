module Api
  module V1
    class MutualFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.mutual_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.mutual_friendships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit: 10)
        friendships = @twitter_user.mutual_friendships.where("sequence >= ?", min_sequence).limit(limit)
        if friendships.empty?
          [[], -1]
        else
          [friendships.map(&:friend_uid), friendships.last.sequence]
        end
      end
    end
  end
end