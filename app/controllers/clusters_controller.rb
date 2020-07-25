class ClustersController < ApplicationController
  include Concerns::SearchRequestConcern

  def new
    @title = t('clusters.new.plain_title')
  end

  def show
    if (stat = UsageStat.find_by(uid: @twitter_user.uid))
      clusters = stat.tweet_clusters
      @cluster_names = clusters.keys.take(10).map { |name| t('clusters.show.cluster_name', name: name) }
      @graph = clusters.to_a.take(30).map { |word, count| {name: word, y: count} }
    else
      @cluster_names = @graph = []
    end
  end
end
