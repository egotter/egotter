module Api
  module V1
    class PeriodicReportSettingsController < ApplicationController

      before_action :require_login!

      layout false

      KEYS = %w(morning afternoon evening send_only_if_changed)

      def update
        setting = current_user.periodic_report_setting

        KEYS.each do |name|
          if params.has_key?(name) && %w(true false).include?(params[name])
            setting.update(name => params[name])
            break
          end
        end

        render json: setting.attributes.slice(*KEYS)
      end
    end
  end
end
