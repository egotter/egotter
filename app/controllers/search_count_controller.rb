class SearchCountController < ApplicationController
  def new
    if UsageCount.exists?
      count = UsageCount.get
      SetUsageCountWorker.perform_async if UsageCount.ttl < 5.minutes
    else
      count = -1
      SetUsageCountWorker.perform_async
    end

    render json: {count: count}
  rescue => e
    render json: {count: -1}
  end
end
