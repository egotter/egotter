class SearchesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper
  include WorkersHelper

  before_action :need_login,     only: %i(force_update)
  before_action :reject_crawler, only: %i(create waiting)
  before_action(only: Search::MENU + %i(create show force_update)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show force_update)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show force_update)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show force_update)) { authorized_search?(@tu) }
  before_action(only: Search::MENU + %i(show force_update)) { existing_uid?(@tu.uid.to_i) }
  before_action only: Search::MENU + %i(show force_update) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action(only: %i(waiting)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(waiting)) { searched_uid?(params[:uid].to_i) }

  before_action only: (%i(new create waiting show force_update) + Search::MENU) do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def show
    redirect_to timeline_path(screen_name: @twitter_user.screen_name)
  end

  def new
  end

  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    redirect_path = sanitized_redirect_path(params[:redirect_path].presence || search_path(screen_name: screen_name))
    if TwitterUser.exists?(uid: uid)
      redirect_to redirect_path
    else
      save_twitter_user_to_cache(uid, screen_name: screen_name, user_info: @tu.user_info)
      add_create_twitter_user_worker_if_needed(uid, user_id: current_user_id, screen_name: screen_name)
      redirect_to waiting_search_path(uid: uid, redirect_path: redirect_path)
    end
  end

  def waiting
    uid = params[:uid].to_i
    tu = fetch_twitter_user_from_cache(uid)
    return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist') if tu.nil?

    @redirect_path = sanitized_redirect_path(params[:redirect_path].presence || search_path(screen_name: tu.screen_name))
    @twitter_user = tu
  end

  def force_reload
    uid = params[:uid].to_i
    if valid_uid?(uid) && existing_uid?(uid)
      ::Cache::PageCache.new.delete(uid)
      return redirect_to search_path(screen_name: TwitterUser.latest(uid).screen_name)
    end

    head :bad_request
  end

  def force_update
    # TODO This action is currently ignored.
    head :ok
  end

  %i(favoriting).each do |menu|
    define_method(menu) do
      @menu = menu
      @title = title_for(menu, @twitter_user.screen_name)
      @description = "#{@title} - #{@twitter_user.description}"
      render :common
    end
  end

  def usage_stats
    redirect_to usage_stat_path(screen_name: @twitter_user.screen_name), status: 301
  end

  %w(new_friends new_followers).each do |menu|
    define_method(menu) do
      redirect_to send("#{menu.remove(/^new_/).singularize}_path", screen_name: @twitter_user.screen_name), status: 301
    end
  end

  def close_friends
    redirect_to close_friend_path(screen_name: @twitter_user.screen_name), status: 301
  end

  def clusters_belong_to
    redirect_to cluster_path(screen_name: @twitter_user.screen_name), status: 301
  end

  %i(inactive_friends inactive_followers friends followers).each do |menu|
    define_method(menu) do
      redirect_to send("#{menu.singularize}_path", screen_name: @twitter_user.screen_name), status: 301
    end
  end

  %w(inactive_friends friends).each do |menu|
    define_method(menu) do
      redirect_to send("#{menu.singularize}_path", screen_name: @twitter_user.screen_name), status: 301
    end
  end

  def inactive_followers
    redirect_to inactive_friend_path(screen_name: @twitter_user.screen_name, type: 'inactive_followers'), status: 301
  end

  def followers
    redirect_to friend_path(screen_name: @twitter_user.screen_name, type: 'followers'), status: 301
  end
end
