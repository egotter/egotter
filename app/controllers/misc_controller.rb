class MiscController < ApplicationController
  include SearchesHelper
  include Logging

  before_action :create_search_log, only: %i(menu)

  def maintenance
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def sitemap
    @logs = BackgroundSearchLog.where(status: true, user_id: -1).order(created_at: :desc).limit(10)
    render layout: false
  end

  def menu
    return redirect_to welcome_path unless user_signed_in?
    if request.patch?
      current_user.notification.update(params.require(:notification).permit(:email, :dm, :news, :search))
      redirect_to menu_path, notice: t('dictionary.settings_saved')
    else
      render
    end
  end

  def support
  end
end
