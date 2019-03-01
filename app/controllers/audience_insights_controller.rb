class AudienceInsightsController < ApplicationController
  include Concerns::Showable

  def show
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name})

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name})

    @chart_builder = AudienceInsight.find_by(uid: @twitter_user.uid) || AudienceInsightChartBuilder.new(@twitter_user.uid)
  end
end
