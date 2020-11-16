class TrendsController < ApplicationController
  def index
    @trends = Trend.japan.latest_trends.top_n(3)
    @time = @trends[0].time
  end
end
