module Api
  module V1
    class AnnouncementsController < ApplicationController
      def list
        html = render_to_string(partial: 'shared/announcements', formats: [:html])
        render json: {html: html}
      end
    end
  end
end
