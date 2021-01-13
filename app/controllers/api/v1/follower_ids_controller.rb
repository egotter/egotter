module Api
  module V1
    class FollowerIdsController < IdsFetcherController
      private

      def worker_class
        FetchFollowerIdsWorker
      end
    end
  end
end
