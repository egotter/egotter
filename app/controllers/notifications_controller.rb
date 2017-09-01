class NotificationsController < ApplicationController

  before_action only: %i(index) do
    push_referer
    create_search_log
  end

  def index
    return redirect_to root_path unless user_signed_in?

    @title = t('.title', user: current_user.mention_name)
    @notifications = current_user.notifications
  end
end
