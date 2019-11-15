class TimelinesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SearchByUidConcern
  include Concerns::AudienceInsights

  after_action {::Util::SearchCountCache.increment}

  def show
    enqueue_update_authorized
    enqueue_audience_insight(@twitter_user.uid)

    @chart_builder = find_or_create_chart_builder(@twitter_user)
  end
end
