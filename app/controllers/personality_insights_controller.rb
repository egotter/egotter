class PersonalityInsightsController < ApplicationController
  include SearchRequestConcern

  before_action :require_signed_in, only: :show
  before_action :set_insight, only: :show
  before_action :has_enough_tweets?, only: :show
  before_action :analyzing_failed?, only: :show
  before_action(only: :show) do
    unless @insight
      if personality_insight_rate_limited? && current_user.sharing_count == 0
        redirect_to personality_insights_top_path(via: current_via('rate_limited')), alert: t('.show.rate_limited_html')
      else
        create_personality_insight
      end
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

  def require_signed_in
    unless user_signed_in?
      message = t('.show.need_login_html', url: sign_in_path(via: current_via, redirect_path: request.fullpath))
      redirect_to personality_insights_top_path(via: current_via('need_sign_in')), alert: message
    end
  end

  def personality_insight_rate_limited?
    CallPersonalityInsightCount.new.rate_limited? && !current_user_has_valid_subscription?
  end

  def current_user_has_valid_subscription?
    user_signed_in? && current_user.has_valid_subscription?
  end

  def has_enough_tweets?
    if @insight&.tweets_not_enough?
      redirect_to personality_insights_top_path(via: current_via('not_enough')), alert: t('.show.tweets_not_enough', user: @twitter_user.screen_name)
    end
  end

  def analyzing_failed?
    if @insight&.analyzing_failed?
      message = t('.show.analyzing_failed', user: @twitter_user.screen_name, count: CreatePersonalityInsightWorker.new.expire_in.seconds)
      redirect_to personality_insights_top_path(via: current_via('failed')), alert: message
    end
  end

  def create_personality_insight
    CreatePersonalityInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
    message = t('.show.personality_is_being_analyzed', user: @twitter_user.screen_name, url: personality_insight_path(@twitter_user, via: current_via('processing')))
    redirect_to personality_insights_top_path(via: current_via('processing')), notice: message
  end
end
