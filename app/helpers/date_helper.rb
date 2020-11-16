module DateHelper
  def distance_of_time_in_words_ja(*args)
    distance_of_time_in_words(*args) + '前'
  end
end
