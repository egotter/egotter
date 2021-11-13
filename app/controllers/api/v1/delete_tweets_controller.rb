module Api
  module V1
    class DeleteTweetsController < ApplicationController

      def faq
        html = render_to_string(partial: 'faq', formats: [:html])
        render json: {html: html}
      end
    end
  end
end
