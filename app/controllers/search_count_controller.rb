class SearchCountController < ApplicationController
  def new
    count =
        if Util::SearchCountCache.exists?
          Util::SearchCountCache.get
        else
          CreateTweetsWorker.perform_async(keyword)
          -1
        end

    render json: {count: count}
  end
end
