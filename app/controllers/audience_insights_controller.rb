class AudienceInsightsController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    @page_title = t('.page_title', user: @twitter_user.screen_name)
    @insight = @twitter_user.audience_insight
  end
end
