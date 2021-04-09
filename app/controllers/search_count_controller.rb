class SearchCountController < ApplicationController

  before_action { self.access_log_disabled = true }

  DEFAULT_COUNT = 275067 # 2019/08/27

  def new
    if UsageCount.exists?
      count = UsageCount.get
      SetUsageCountWorker.perform_async if UsageCount.ttl < 5.minutes
    else
      count = DEFAULT_COUNT
      SetUsageCountWorker.perform_async
    end

    render json: {count: count}
  rescue => e
    render json: {count: DEFAULT_COUNT}
  end
end
