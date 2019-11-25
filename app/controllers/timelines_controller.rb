class TimelinesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SearchRequestConcern
  include Concerns::AudienceInsights

  after_action {::Util::SearchCountCache.increment}

  def show
    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight(@twitter_user.uid)

    @chart_builder = find_or_create_chart_builder(@twitter_user)

    if @twitter_user.profile_not_found?
      flash.now[:alert] = profile_not_found_message(@twitter_user.screen_name, request.path)
    end
  end
end
