class TimelinesController < ApplicationController
  include JobQueueingConcern
  include SearchRequestConcern
  include SearchHistoriesConcern

  before_action do
    create_search_history(@twitter_user)
    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight(@twitter_user.uid)
    enqueue_assemble_twitter_user(@twitter_user)
    @jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id)
  end

  after_action { UsageCount.increment }

  def show
  end
end
