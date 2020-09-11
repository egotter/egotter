class PersonalityInsightsController < ApplicationController
  include SearchRequestConcern

  before_action(only: :show) do
    if !from_crawler? && !user_signed_in?
      message = t('before_sign_in.need_login_html', url: sign_in_path(via: current_via, redirect_path: request.fullpath))
      redirect_to personality_insights_top_path, alert: message
    end
  end
  before_action(only: :show) do
    if !(insight = set_insight)
      if CallPersonalityInsightCount.new.rate_limited?
        redirect_to personality_insights_top_path, alert: t('.show.rate_limited')
      else
        CreatePersonalityInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
        redirect_to personality_insights_top_path, notice: t('.show.personality_is_being_analyzed', user: @twitter_user.screen_name, url: personality_insight_path(@twitter_user))
      end
    elsif insight.tweets_not_enough?
      redirect_to personality_insights_top_path, alert: t('.show.tweets_not_enough', user: @twitter_user.screen_name)
    elsif insight.analyzing_failed?
      redirect_to personality_insights_top_path, alert: t('.show.analyzing_failed', user: @twitter_user.screen_name, count: CreatePersonalityInsightWorker.new.expire_in.seconds)
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
end
