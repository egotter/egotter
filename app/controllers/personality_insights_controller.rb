class PersonalityInsightsController < ApplicationController
  include SearchRequestConcern

  before_action(only: :show) do
    if !from_crawler? && !user_signed_in?
      message = t('before_sign_in.need_login_html', url: sign_in_path(via: current_via, redirect_path: request.fullpath))
      redirect_to personality_insights_top_path(via: current_via('need_sign_in')), alert: message
    end
  end
  before_action(only: :show) do
    if !(insight = set_insight)
      if CallPersonalityInsightCount.new.rate_limited? && !current_user_has_valid_subscription?
        redirect_to personality_insights_top_path(via: current_via('rate_limited')), alert: t('.show.rate_limited_html')
      else
        CreatePersonalityInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
        message = t('.show.personality_is_being_analyzed', user: @twitter_user.screen_name, url: personality_insight_path(@twitter_user, via: current_via('processing')))
        redirect_to personality_insights_top_path(via: current_via('processing')), notice: message
      end
    elsif insight.tweets_not_enough?
      redirect_to personality_insights_top_path(via: current_via('not_enough')), alert: t('.show.tweets_not_enough', user: @twitter_user.screen_name)
    elsif insight.analyzing_failed?
      redirect_to personality_insights_top_path(via: current_via('failed')), alert: t('.show.analyzing_failed', user: @twitter_user.screen_name, count: CreatePersonalityInsightWorker.new.expire_in.seconds)
    end
  end

  def new
  end

  def show
  end

  private

  def set_insight
    @insight = PersonalityInsight.find_by(uid: @twitter_user.uid)
  end

  def current_user_has_valid_subscription?
    user_signed_in? && current_user.has_valid_subscription?
  end
end
