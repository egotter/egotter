module WelcomeReportsHelper
  def show_dm_confirmation_announcement?
    top = controller_name == 'home' && action_name == 'new'

    if !top && controller_name != 'access_confirmations'
      !user_signed_in? || (current_user.created_at >= 1.day.ago && !PeriodicReport.messages_allotted?(current_user))
    end
  end
end
