class SearchCountController < ApplicationController
  def new
    if UsageCount.exists?
      count = UsageCount.get
      SetUsageCountWorker.perform_async if UsageCount.ttl < 5.minutes
    else
      logger.warn 'UsageCount is not found'
      count = User.all.size
      SetUsageCountWorker.perform_async
    end

    render json: {count: count}
  rescue => e
    render json: {count: -1}
  end
end
