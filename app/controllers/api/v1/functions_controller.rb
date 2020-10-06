module Api
  module V1
    class FunctionsController < ApplicationController

      before_action { self.access_log_disabled = true }

      def list
        html = render_to_string(partial: 'shared/functions', formats: [:html])
        render json: {html: html}
      end
    end
  end
end
