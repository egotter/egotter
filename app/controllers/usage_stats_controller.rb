class UsageStatsController < ApplicationController
  include Concerns::SearchRequestConcern

  before_action(only: :show) do
    unless set_stat
      redirect_to root_path, alert: t('.show.not_found_html', user: @twitter_user.screen_name, url: timeline_path(@twitter_user))
    end
  end

  def show
    @usage_time = @stat.chart_data(:usage_time)
  end

  private

  def set_stat
    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
