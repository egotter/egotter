class WordCloudsController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    if (stat = UsageStat.find_by(uid: @twitter_user.uid)) && stat.words_count
      @words_count = stat.words_count.sort_by { |_, count| -count }.map { |word, count| {word: word, count: count} }
    else
      @words_count = []
    end
  end
end
