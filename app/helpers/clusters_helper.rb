module ClustersHelper
  def name_y_format(tweet_clusters)
    tweet_clusters.to_a.take(10).map { |word, count| {name: word, y: count} }
  end
end
