class AudienceInsightsController < ApplicationController
  include SearchRequestConcern

  before_action(only: :show) do
    unless set_insight
      url = timeline_path(@twitter_user, via: current_via('not_found'))
      redirect_to root_path(via: current_via('not_found')), alert: t('.show.not_found_html', user: @twitter_user.screen_name, url: url)
    end
  end

  def show
  end

  private

  def set_insight
    @insight = @twitter_user.audience_insight
  end
end
