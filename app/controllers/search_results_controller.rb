class SearchResultsController < ApplicationController
  include Validation
  include Logging
  include SearchesHelper
  include PageCachesHelper
  include TweetTextHelper

  layout false

  before_action :need_login, only: %i(common_friends common_followers)
  before_action(only: %i(show) + Search::MENU) { valid_uid?(params[:id].to_i) }
  before_action(only: %i(show) + Search::MENU) { existing_uid?(params[:id].to_i) }
  before_action(only: %i(show) + Search::MENU) { @searched_tw_user = fetch_twitter_user_with_client(params[:id].to_i) }
  before_action(only: %i(show) + Search::MENU) { authorized_search?(@searched_tw_user) }

  def show
    tu = @searched_tw_user
    user_id = current_user_id

    add_background_search_worker_if_needed(tu.uid, user_id: user_id, screen_name: tu.screen_name)

    html = ::Cache::PageCache.new.fetch(tu.uid) do
      create_instance_variables_for_result_page(tu, login_user: User.find_by(id: user_id))
      render_to_string
    end

    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user_id} #{request.device_type}"
    logger.info e.backtrace.slice(0, 10).join("\n")
    render nothing: true, status: 500
  end

  %i(friends followers removing removed new_friends new_followers blocking_or_blocked).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu)).items
      render json: {html: render_to_string(partial: 'common', locals: {menu: menu})}, status: 200
    end
  end

  %i(one_sided_friends one_sided_followers mutual_friends).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu)).items
      @graph = @searched_tw_user.mutual_friends_graph
      @tweet_text = mutual_friends_text(@searched_tw_user)
      render json: {html: render_to_string(partial: 'common', locals: {menu: menu})}, status: 200
    end
  end

  %i(common_friends common_followers).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu, current_user.twitter_user)).items
      @graph = @searched_tw_user.send("#{menu}_graph", current_user.twitter_user)
      @tweet_text = send("#{menu}_text", @user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user, @user_items.size - 3)
      render json: {html: render_to_string(partial: 'common', locals: {menu: menu})}, status: 200
    end
  end

  %i(replying replied favoriting close_friends).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu)).items
      @graph =
        if menu == :replied
          @searched_tw_user.send("#{menu}_graph", login_user: User.find_by(id: current_user_id))
        else
          @searched_tw_user.send("#{menu}_graph")
        end

      @tweet_text = close_friends_text(@user_items.map { |i| i[:target] }, @searched_tw_user)
      render json: {html: render_to_string(partial: 'common', locals: {menu: menu})}, status: 200
    end
  end

  %i(inactive_friends inactive_followers).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu)).items
      @graph = @searched_tw_user.send("#{menu}_graph")
      @tweet_text = inactive_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
      render json: {html: render_to_string(partial: 'common', locals: {menu: menu})}, status: 200
    end
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = @searched_tw_user.clusters_belong_to
    @cluster_words = clusters.keys.slice(0, 10).map { |c| {target: "#{c}#{t('searches.common.cluster')}"} }
    @graph = @searched_tw_user.clusters_belong_to_frequency_distribution
    @clusters_belong_to_cloud = @searched_tw_user.clusters_belong_to_cloud
    @tweet_text = clusters_belong_to_text(@cluster_words.slice(0, 3).map { |c| c[:target] }, @searched_tw_user)
    render json: {html: render_to_string(partial: 'clusters_belong_to')}, status: 200
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    @wday, @wday_drilldown, @hour, @hour_drilldown, @usage_time = @searched_tw_user.usage_stats

    statuses = @searched_tw_user.statuses
    statuses_size = statuses.size
    @kind = {
      mentions: statuses.select { |s| s.mentions? }.size.to_f / statuses_size * 100,
      media: statuses.select { |s| s.media? }.size.to_f / statuses_size * 100,
      urls: statuses.select { |s| s.urls? }.size.to_f / statuses_size * 100,
      hashtags: statuses.select { |s| s.hashtags? }.size.to_f / statuses_size * 100,
      location: statuses.select { |s| s.location? }.size.to_f / statuses_size * 100
    }

    hashtags = @searched_tw_user.hashtags
    @cloud = hashtags.map.with_index { |(word, count), i| {text: word, size: count, group: i % 3} }
    @hashtags = hashtags.to_a.slice(0, 10).map { |word, count| {name: word, y: count} }

    render json: {html: render_to_string(partial: 'usage_stats')}, status: 200
  end
end