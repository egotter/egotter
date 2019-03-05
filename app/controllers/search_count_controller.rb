class SearchCountController < ApplicationController
  def new
    count =
        if ::Util::SearchCountCache.exists?
          ::Util::SearchCountCache.get
        else
          SetSearchCountWorker.perform_async
          -1
        end

    render json: {count: count}
  end
end
