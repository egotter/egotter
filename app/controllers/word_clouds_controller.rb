class WordCloudsController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    if (words_count = UsageStat.find_by(uid: @twitter_user.uid)&.sorted_words_count)
      @words_count = words_count
    else
      @words_count = {}
    end
  end
end
