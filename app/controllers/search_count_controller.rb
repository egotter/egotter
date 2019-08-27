class SearchCountController < ApplicationController
  def new
    count =
        if ::Util::SearchCountCache.exists?
          ::Util::SearchCountCache.get
        else
          SetSearchCountWorker.perform_async
          275067 # 2019/08/27
        end

    render json: {count: count}
  end
end
