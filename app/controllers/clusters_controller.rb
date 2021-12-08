class ClustersController < ApplicationController
  include SearchRequestCreation

  def new
    @title = t('clusters.new.plain_title')
  end

  def show
    if (@clusters = @twitter_user.usage_stat&.sorted_tweet_clusters)
      clusters = @clusters.take(3).map { |word, _| t('.cluster_name', name: word) }.join("\n")
      @tweet_text = t('clusters.show.tweet', user: @twitter_user.screen_name, clusters: clusters, url: cluster_url(@twitter_user))
      @cluster_names_str = @clusters.take(3).map(&:first).join(' ')
    else
      @clusters = {}
      @tweet_text = @cluster_names_str = ''
    end
  end
end
