class ClustersController < ApplicationController
  include Validation
  include SearchesHelper
  include ClustersHelper
  include TweetTextHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create show)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action(only: %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(create show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action only: %i(new create show) do
    if request.format.html?
      push_referer
      create_search_log
    end
  end

  def new
    @title = t('clusters.new.plain_title')
  end

  def create
    redirect_path = cluster_path(screen_name: @tu.screen_name)
    if TwitterUser.exists?(uid: @tu.uid)
      redirect_to redirect_path
    else
      @screen_name = @tu.screen_name
      @redirect_path = redirect_path
      @via = params['via']
      render template: 'searches/create', layout: false
    end
  end

  def show
    stat = UsageStat.find_by(uid: @twitter_user.uid)
    if stat
      clusters = stat.tweet_clusters
      @cluster_names = clusters.keys.take(10).map { |name| t('clusters.show.cluster_name', name: name) }
      @graph = name_y_format(clusters)
      @word_cloud = text_size_group_format(clusters)
    else
      @cluster_names = @graph = @word_cloud = []
    end
  end
end
