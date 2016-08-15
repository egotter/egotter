class SearchesController < ApplicationController
  include Validation
  include Logging
  include SearchesHelper
  include PageCachesHelper

  before_action :reject_crawler,      only: %i(create)
  before_action :valid_search_value?, only: %i(create)
  before_action :need_login,          only: %i(common_friends common_followers)
  before_action :set_twitter_user,    only: Search::MENU + %i(show)

  before_action only: (%i(new create waiting show) + Search::MENU) do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session[:sign_in_from])
      session.delete(:sign_in_from)
    elsif session[:sign_out_from].present?
      create_search_log(referer: session[:sign_out_from])
      session.delete(:sign_out_from)
    else
      create_search_log
    end
  end

  def show
    @title = t('.title', user: @searched_tw_user.mention_name)

    user_id = current_user_id
    page_cache = PageCache.new(redis)
    if page_cache.exists?(@searched_tw_user.uid, user_id)
      @page_cache = page_cache.read(@searched_tw_user.uid, user_id)
    end
  end

  def new
  end

  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    user_id = current_user_id

    save_twitter_user_to_cache(uid, user_id, screen_name: screen_name, user_info: @tu.user_info)
    add_background_search_worker_if_needed(uid, user_id, screen_name: screen_name)

    if TwitterUser.exists?(uid: uid, user_id: user_id)
      redirect_to search_path(screen_name: screen_name, id: uid)
    else
      redirect_to waiting_path(screen_name: screen_name, id: uid)
    end
  end

  # GET /searches/:screen_name/waiting
  def waiting
    unless TwitterUser.new(uid: params[:id]).valid_uid?
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    uid = params[:id].to_i
    user_id = current_user_id
    unless Util::SearchedUidList.new(redis).exists?(uid, user_id)
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    @searched_tw_user = fetch_twitter_user_from_cache(uid, user_id)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    redirect_to '/', alert: BackgroundSearchLog::SomethingError::MESSAGE
  end

  Search::MENU.each do |menu|
    define_method(menu) do
      @menu = menu
      @title = t('.title', user: @searched_tw_user.mention_name)
      render :common
    end
  end

  def debug
    unless request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: #{current_user_id} #{request.device_type} #{request.method} #{request.url}"
    end
    redirect_to '/'
  end
end
