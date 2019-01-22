module Api
  module V1
    class ProtectionController < ::Api::Base

      before_action :require_login!

      def summary
        hacked = select_hacked_statuses(@twitter_user)
        render json: {name: controller_name, count: hacked.size}
      end

      def list
        hacked = select_hacked_statuses(@twitter_user)

        if params[:html]
          hacked =
            if @twitter_user.protected_account?
              render_to_string partial: 'twitter/tweet', collection: hacked, cached: true, formats: %i(html)
            else
              render_to_string partial: 'twitter/oembed_tweet', collection: hacked, as: :tweet, cached: true, formats: %i(html)
            end
        end

        render json: {name: controller_name, max_sequence: -1, limit: -1, statuses: hacked}
      end

      private

      # TODO Experimental
      def select_hacked_statuses(twitter_user)
        []
      end
    end
  end
end