class TimelinesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SearchRequestConcern

  before_action do
    unless from_crawler?
      CreateSearchHistoryWorker.new.perform(@twitter_user.uid, session_id: egotter_visit_id, user_id: current_user_id, ahoy_visit_id: current_visit&.id, via: params[:via])
    end

    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight(@twitter_user.uid)
    enqueue_assemble_twitter_user(@twitter_user)
  end

  after_action { UsageCount.increment }

  def show
  end
end
