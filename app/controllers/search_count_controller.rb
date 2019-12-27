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
    logger.warn "#{controller_name}##{action_name} #{e.inspect}"
    logger.info e.backtrace.join("\n")
    render json: {count: DEFAULT_COUNT}
  end
end
