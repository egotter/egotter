class TimelinesController < ApplicationController
  include Concerns::JobQueueingConcern
  include Concerns::SearchRequestConcern
  include Concerns::AudienceInsights

  after_action {::Util::SearchCountCache.increment}

  def show
    CreateSearchHistoryWorker.perform_async(fingerprint, current_user_id, @twitter_user.uid, current_visit&.id, via: params[:via]) unless from_crawler?
    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight(@twitter_user.uid)

    @chart_builder = find_or_create_chart_builder(@twitter_user)

    if @twitter_user.profile_not_found?
      logger.warn "#{controller_name}##{action_name} Profile not found in EFS and S3. #{@twitter_user.id} #{sprintf("%.3f sec", Time.zone.now - @twitter_user.created_at)}"
      flash.now[:alert] = profile_not_found_message(@twitter_user.screen_name, request.path)
    end
  end
end
