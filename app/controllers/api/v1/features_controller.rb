module Api
  module V1
    class FeaturesController < ApplicationController
      def list
        html = render_to_string(partial: 'shared/features', formats: [:html])
        render json: {html: html}
      end
    end
  end
end
