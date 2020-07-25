class ClustersController < ApplicationController
  include Concerns::SearchRequestConcern

  def new
    @title = t('clusters.new.plain_title')
  end

  def show
    text = @twitter_user.status_tweets.map(&:text).join('').gsub(/[\n']/, ' ')
    @clusters = UsageStat::TweetCluster.new.count_words(text).take(30)

    clusters = @clusters.take(3).map { |word, _| t('.cluster_name', name: word) }.join("\n")
    @tweet_text = t('clusters.show.tweet', user: @twitter_user.screen_name, clusters: clusters, url: cluster_url(@twitter_user))

    @cluster_names_str = @clusters.take(3).map(&:first).join(' ')
  end
end
