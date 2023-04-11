module WelcomeReportsHelper
  def show_dm_confirmation_announcement?
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: #show_dm_confirmation_announcement? is stopped'
      return false
    end

    timeline_page? &&
        (!user_signed_in? || (current_user.created_at >= 1.day.ago && !PeriodicReport.messages_allotted?(current_user)))
  end
end
