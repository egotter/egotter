module Api
  module V1
    class UnfriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        relation = @twitter_user.unfriendships
        [relation.limit(limit).pluck(:friend_uid), relation.size]
      end

      def list_uids(min_sequence, limit:)
        relation = @twitter_user.unfriendships.where("sequence >= ?", min_sequence).limit(limit)
        if relation.empty?
          [[], -1]
        else
          [relation.map(&:friend_uid), relation.last.sequence]
        end
      end

      def list_users
        @twitter_user.unfriends
      end
    end
  end
end