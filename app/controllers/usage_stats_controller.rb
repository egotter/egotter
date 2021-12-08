class UsageStatsController < ApplicationController
  include SearchRequestCreation

  before_action(only: :show) do
    unless set_stat
      url = timeline_path(@twitter_user, via: current_via('not_found'))
      redirect_to root_path(via: current_via('not_found')), alert: t('.show.not_found_html', user: @twitter_user.screen_name, url: url)
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
