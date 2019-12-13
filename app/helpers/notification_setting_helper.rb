module NotificationSettingHelper
  def report_interval_options_for_select(user)
    options =
        NotificationSetting::REPORT_INTERVAL_VALUES.map do |value|
          [t("settings.index.report_interval.#{value}"), value]
        end

    disabled_values =
        if user.has_valid_subscription?
          []
        else
          NotificationSetting::REPORT_INTERVAL_VALUES.select do |value|
            value < NotificationSetting::DEFAULT_REPORT_INTERVAL
          end
        end


    options_for_select(options, selected: user.notification_setting.report_interval, disabled: disabled_values)
  end
end
