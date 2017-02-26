module ClustersHelper
  def name_y_format(tweet_clusters)
    tweet_clusters.to_a.take(10).map { |word, count| {name: word, y: count} }
  end

  def text_size_group_format(tweet_clusters)
    tweet_clusters.map.with_index { |(word, count), i| {text: word, size: count, group: i % 3} }
  end
end
