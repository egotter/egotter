module Api
  module V1
    class ShareCandidateTweetsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def index
        render json: {tweets: ShareTweets.load}
      end
    end
  end
end
