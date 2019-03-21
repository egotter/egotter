class NotificationsController < ApplicationController

  before_action :require_login!

  before_action only: %i(index) do
    push_referer
    create_search_log
  end

  def index
    @title = t('.title', user: current_user.mention_name)
    @notifications = fetch_reports
  end

  private

  def fetch_reports
    user = current_user
    reports = user.search_reports.where.not(message: ['', nil]) +
        user.news_reports.where.not(message: ['', nil]) +
        user.prompt_reports.where.not(message: ['', nil]) +
        user.welcome_messages.where.not(message: ['', nil])

    reports.sort_by {|r| -r.created_at.to_i}.take(3)
  end
end
