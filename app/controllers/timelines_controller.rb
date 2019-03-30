class TimelinesController < ApplicationController
  include WorkersHelper
  include Concerns::SearchByUidConcern
  include Concerns::AudienceInsights

  after_action {::Util::SearchCountCache.increment}

  def show
    enqueue_update_authorized
    enqueue_create_cache
    enqueue_audience_insight(@twitter_user.uid)

    @chart_builder = find_or_create_chart_builder(@twitter_user)
  end
end
