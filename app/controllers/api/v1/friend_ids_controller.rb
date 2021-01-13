module Api
  module V1
    class FriendIdsController < IdsFetcherController
      private

      def worker_class
        FetchFriendIdsWorker
      end
    end
  end
end
