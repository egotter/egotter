class TimelinesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SearchRequestConcern
  include Concerns::AudienceInsights

  after_action { UsageCount.increment }

  after_action do
    logger.info "Benchmark RenderView #{controller_name}##{action_name} #{@view_benchmark.inspect}"
  end

  def show
    CreateSearchHistoryWorker.perform_async(egotter_visit_id, current_user_id, @twitter_user.uid, current_visit&.id, via: params[:via]) unless from_crawler?
    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight(@twitter_user.uid)

    @chart_builder = find_or_create_chart_builder(@twitter_user)

    @view_benchmark = {}
  end
end
