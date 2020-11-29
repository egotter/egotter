module DateHelper
  # Example: 1.hour
  def distance_of_time_in_words_ja(*args)
    distance_of_time_in_words(*args) + '前'
  end

  # Example: 1.hour.ago
  def time_ago_in_words_ja(*args)
    time_ago_in_words(*args) + '前'
  end
end
