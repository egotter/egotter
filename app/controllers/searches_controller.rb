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
    @searched_tw_user = TwitterUser.latest(@tu.uid.to_i)
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
    tu = @searched_tw_user
    page_cache = ::Cache::PageCache.new
    if tu.forbidden_account?
      flash.now[:alert] = forbidden_message(tu.screen_name)
      @worker_started = false
      @page_cache = page_cache.read(tu.uid) if page_cache.exists?(tu.uid)
      return render
    end

    if via_notification?
      if via_prompt_report?
        # A worker is started because the record is not updated in the process of creating a prompt report.
        @worker_started = !!add_create_twitter_user_worker_if_needed(tu.uid, user_id: current_user_id, screen_name: tu.screen_name)
      else
        # When a guest or user accesses this action via a notification which includes search and update,
        # no worker is started. Because the record is updated in the process of creating a notification.
        # page_cache.delete(tu.uid)
      end
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
    if tu.nil?
      return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end
    @redirect_path = sanitized_redirect_path(params[:redirect_path].presence || search_path(screen_name: tu.screen_name))
    @searched_tw_user = tu
  end

  def force_reload
    uid = params[:uid].to_i
    if valid_uid?(uid) && existing_uid?(uid)
      ::Cache::PageCache.new.delete(uid)
      redirect_to search_path(screen_name: TwitterUser.latest(uid).screen_name)
    end

    head :bad_request
  end

  def force_update
    # TODO This action is currently ignored.
    head :ok
  end

  %i(close_friends usage_stats new_friends new_followers favoriting).each do |menu|
    define_method(menu) do
      @menu = menu
      @title = title_for(menu, @searched_tw_user.screen_name)
      render :common
    end
  end

  %i(clusters_belong_to).each do |menu|
    define_method(menu) do
      redirect_to cluster_path(screen_name: @searched_tw_user.screen_name), status: 301
    end
  end
end
