module WelcomeReportsHelper
  def show_dm_confirmation_announcement?
    timeline_page? &&
        (!user_signed_in? || (current_user.created_at >= 1.day.ago && !PeriodicReport.messages_allotted?(current_user)))
  end
end
