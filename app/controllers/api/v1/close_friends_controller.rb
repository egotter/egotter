module Api
  module V1
    class CloseFriendsController < ::Api::V1::Base

      def show
        # CreateCloseFriendsOgImageWorker.perform_async(@twitter_user.uid) if user_signed_in?
        summary
      end

      def og_image
        users = @twitter_user.close_friends(limit: CLOSE_FRIENDS_SUMMARY_LIMIT).map { |u| u.slice(:screen_name, :profile_image_url_https) }
        text = I18n.t('og_image_text.close_friends', user: @twitter_user.screen_name, friend1: users[0][:screen_name], friend2: users[1][:screen_name], friend3: users[2][:screen_name])
        render json: {text: text, users: users}
      end

      private

      # The heart shape is made up of 65 squares
      CLOSE_FRIENDS_SUMMARY_LIMIT = 70

      def summary_uids(*)
        uids = @twitter_user.close_friend_uids.take(CLOSE_FRIENDS_SUMMARY_LIMIT)
        size = @twitter_user.close_friend_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.close_friends
      end
    end
  end
end