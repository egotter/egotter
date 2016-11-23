class SearchesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper

  before_action :need_login,     only: %i(common_friends common_followers)
  before_action :reject_crawler, only: %i(create)
  before_action(only: Search::MENU + %i(create show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show)) { authorized_search?(@tu) }
  before_action(only: Search::MENU + %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: Search::MENU + %i(show) do
    @searched_tw_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action(only: %i(waiting)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(waiting)) { searched_uid?(params[:uid].to_i) }

  before_action only: (%i(new create waiting show) + Search::MENU) do
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
    tu = @searched_tw_user
    page_cache = ::Cache::PageCache.new
    if via_notification?
      # When a guest or user accesses this action via a notification which includes search, update and prompt_report,
      # no worker is started. Because the record is updated in the process of creating a notification.
      page_cache.delete(tu.uid)
    else
      # Under the following circumstances, a worker is started.
      # 1. When a guest or user accesses this action directly
      # 2. When a guest or user accesses `create` action and searched TwitterUser exists
      @worker_started = !!add_create_twitter_user_worker_if_needed(tu.uid, user_id: current_user_id, screen_name: tu.screen_name)
      @page_cache = page_cache.read(tu.uid) if page_cache.exists?(tu.uid)
    end
  end

  def new
  end

  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    if TwitterUser.exists?(uid: uid)
      redirect_to search_path(screen_name: screen_name)
    else
      save_twitter_user_to_cache(uid, screen_name: screen_name, user_info: @tu.user_info)
      add_create_twitter_user_worker_if_needed(uid, user_id: current_user_id, screen_name: screen_name)
      redirect_to waiting_search_path(uid: uid)
    end
  end

  def waiting
    uid = params[:uid].to_i
    tu = fetch_twitter_user_from_cache(uid)
    if tu.nil?
      return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end
    @searched_tw_user = tu
  end

  Search::MENU.each do |menu|
    define_method(menu) do
      @menu = menu
      @title = title_for(@searched_tw_user, menu: menu)
      render :common
    end
  end

  def debug
    unless request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: #{current_user_id} #{request.device_type} #{request.method} #{request.url}"
    end
    redirect_to root_path
  end
end
