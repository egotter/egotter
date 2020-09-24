class TimelinesController < ApplicationController
  include JobQueueingConcern
  include SearchRequestConcern

  before_action do
    enqueue_update_authorized
    enqueue_update_egotter_friendship
  end

  after_action { UsageCount.increment }

  def show
  end
end
