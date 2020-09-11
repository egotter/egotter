class BlockingOrBlockedController < ApplicationController
  include SearchRequestConcern
  include JobQueueingConcern

  def show
    @jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id)
    @active_tab = 2
    render template: 'result_pages/show' unless performed?
  end
end
