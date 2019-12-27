class SearchCountController < ApplicationController
  DEFAULT_COUNT = 275067 # 2019/08/27

  def new
    count =
        if UsageCount.exists?
          UsageCount.get
        else
          SetUsageCountWorker.perform_async
          DEFAULT_COUNT
        end

    render json: {count: count}
  rescue => e
    notify_airbrake(e)
    render json: {count: DEFAULT_COUNT}
  end
end
