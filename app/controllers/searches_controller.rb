class SearchesController < ApplicationController
  include Validation
  include Logging
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
  before_action(only: %i(waiting)) { valid_uid?(params[:id].to_i) }
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
    page_cache = ::Cache::PageCache.new
    if page_cache.exists?(@searched_tw_user.uid)
      @page_cache = page_cache.read(@searched_tw_user.uid)
    end
  end

  def new
  end

  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    save_twitter_user_to_cache(uid, screen_name: screen_name, user_info_gzip: @tu.user_info_gzip)
    add_background_search_worker_if_needed(uid, user_id: current_user_id, screen_name: screen_name)

    if TwitterUser.exists?(uid: uid)
      redirect_to search_path(screen_name: screen_name, id: uid)
    else
      redirect_to waiting_path(id: uid)
    end
  end

  def waiting
    uid = params[:id].to_i
    unless Util::SearchedUidList.new(redis).exists?(uid)
      return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end

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
